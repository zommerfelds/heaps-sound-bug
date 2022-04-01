import haxe.Timer;
import h2d.col.Point;
import haxe.ds.Option;
import Utils.*;

using Lambda;

// @:expose
class HerbalTeaApp extends hxd.App {
	function onload() {}

	// public static var save:SaveState;
	public static var debugNoFog = false;
	public static var debugShowFps = false;

	public static var avgUpdateTime = 0.0;
	public static var avgRenderTime = 0.0;

	// https://developer.android.com/guide/topics/display-cutout
	public static var cutout = {
		top: 0,
		bottom: 0,
		left: 0,
		right: 0,
	};

	var currentState:GameState;
	var nextState:GameState;
	var renderedCurrentState = false;
	final pak = new hxd.fmt.pak.FileSystem();

	// Can be used for debugging in JavaScript console.
	static function writeSave() {
		// hxd.Save.save(save);
	}

	override function init() {
		// save = hxd.Save.load(new SaveState());
		// trace("Save: " + App.save);
		// SaveState.upgradeToLatestVersion(save);
		// hxd.Save.save(save);

		// debugShowFps = save.optionsDebugMode;

		// Load resources from PAK file
		var loader = new hxd.net.BinaryLoader("build/res.pak");
		loader.onLoaded = (data) -> {
			pak.addPak(new hxd.fmt.pak.FileSystem.FileInput(data));
			hxd.Res.loader = new hxd.res.Loader(pak);
			init2();
		}
		loader.load();

		// The above can be replaced by this for embedded files:
		// hxd.Res.initEmbed(); init2();
	}

	function preloadResourcesRec(directory:hxd.fs.FileEntry) {
		final it = directory.iterator();
		while (it.hasNext()) {
			final node = it.next();
			if (node.isDirectory) {
				preloadResourcesRec(node);
			} else {
				switch (node.path.substr(node.path.length - 4).toLowerCase()) {
					case ".png":
						hxd.Res.load(node.path).toTexture();
					case ".wav" | ".mp3":
						hxd.Res.load(node.path).toSound().getData();
					case ".fnt":
					// Texture file is already loaded via png. Actual font building can't be done
					// since we don't know if it's a normal font or SDF. Skip this case.
					case x:
						throw 'Error loading resource "${node.name}" (unidentified type "$x")';
				}
			}
		}
	}

	function init2() {
		trace("Screen size: " + engine.width + "/" + engine.height);

		// Preload assets to memory and GPU so it doesn't lag mid game.
		final t0 = Timer.stamp();
		preloadResourcesRec(pak.getRoot());
		trace('Took ${floatToStr(Timer.stamp() - t0)}s to load assets.');

		// Sound.init();

		final cutoutJs = js.Syntax.code("window.cutout");
		if (cutoutJs != null) {
			cutout.top = Std.int(cutoutJs.top);
			cutout.bottom = Std.int(cutoutJs.bottom);
			cutout.left = Std.int(cutoutJs.left);
			cutout.right = Std.int(cutoutJs.right);
		}
		trace("Loaded Android cutout: " + cutout);

		// Only for testing:
		var startState = "main";
		var startOcean = "GreenIslands";
		var startStage = 0;
		var startLevel = 0;
		var startSeed = Std.random(0x7FFFFFFF);
		var testScenario:Option<Int> = None;

		#if js
		// This will signal that the Heaps canvas is ready.
		// This is used to hide the loading screen.
		js.Browser.document.dispatchEvent(new js.html.Event("heapsready"));

		var params = new js.html.URLSearchParams(js.Browser.window.location.search);
		startState = params.get("start");
		debugNoFog = params.get("nofog") != null;
		debugShowFps = debugShowFps || params.get("fps") != null;
		if (params.get("ocean") != null) {
			startOcean = params.get("ocean");
		}
		if (params.get("stage") != null) {
			startStage = Std.parseInt(params.get("stage"));
		}
		if (params.get("level") != null) {
			startLevel = Std.parseInt(params.get("level"));
		}
		if (params.get("seed") != null) {
			startSeed = Std.parseInt(params.get("seed"));
		}
		if (params.get("cutouttop") != null) {
			cutout.top = Std.parseInt(params.get("cutouttop"));
		}

		js.Browser.window.addEventListener('error', (event:js.html.ErrorEvent) -> {
			trace("Error handler: " + event.error);
			// NOTE: errors are also being caught and sent to Firebase in cordova/www/index.html
			// js.Lib.debug();
		});

		var intent = js.Syntax.code("window.intent");
		if (intent != null && intent.action == "com.google.intent.action.TEST_LOOP") {
			testScenario = Some(1);
			if (intent.extras != null && intent.extras.scenario) {
				testScenario = Some(untyped intent.extras.scenario);
			}
			haxe.Timer.delay(() -> {
				trace("Testing scenario done");
				js.Syntax.code("navigator.app.exitApp();");
			}, 30000);
		}
		if (startState == "testScenario1") {
			testScenario = Some(1);
		}

		if (testScenario.match(Some(_))) {
			trace("testScenario: " + testScenario);
		}
		switch (testScenario) {
			case Some(1):
				debugShowFps = true;
				startState = "testScenario1";
				function simulate() {
					trace("Simulating tap");
					final window = hxd.Window.getInstance();
					var tap = new Point(1, 0);
					// This angle avoids islands for a long time:
					// tap.rotate(0.50);
					// This angle hits after a few seconds:
					tap.rotate(0.60);
					// This angle hits an island pretty fast:
					// tap.rotate(0.95);
					tap.scale(100);
					tap = tap.add(new Point(window.width / 2, window.height / 2));
					final event = new hxd.Event(EPush, tap.x, tap.y);
					hxd.Window.getInstance().event(event);
					haxe.Timer.delay(simulate, 1000);
				}
				simulate();
			case Some(x):
				trace('WARNING: test scenario $x doesn\'t exist');
			case None:
		}
		if (testScenario != None) {
			var counter = 0;
			var fpsAvg = 0.0;
			var updateTimeTotAvg = 0.0;
			var renderTimeTotAvg = 0.0;
			function logStats() {
				final fps = hxd.Timer.fps();
				fpsAvg = (fpsAvg * counter + fps) / (counter + 1);
				updateTimeTotAvg = (updateTimeTotAvg * counter + avgUpdateTime) / (counter + 1);
				renderTimeTotAvg = (renderTimeTotAvg * counter + avgRenderTime) / (counter + 1);
				final drawCalls = engine.drawCalls;
				counter++;
				trace('Perf[$counter] FPS: ${floatToStr(fps)} (${floatToStr(fpsAvg)} avg) updateT: ${floatToStr(avgUpdateTime * 1000)} (${floatToStr(updateTimeTotAvg * 1000)} avg) renderT: ${floatToStr(avgRenderTime * 1000)} (${floatToStr(renderTimeTotAvg * 1000)} avg) draw calls: ${drawCalls}');
				haxe.Timer.delay(logStats, 1000);
			}
			logStats();
		}
		#end

		if (startState != "") {
			trace("startState: " + startState);
		}

		// engine.backgroundColor = 0xff6fc8e8;

		// switchState(...)

		#if js
		if (js.Browser.document.addEventListener != null) {
			js.Browser.document.addEventListener("backbutton", onBackButton, false);
		}
		#end

		onload();
	}

	function onBackButton() {
		trace("Back button");
		if (currentState != null) {
			currentState.onBackButton();
		}
	}

	public function switchState(state:GameState) {
		if (currentState != null) {
			currentState.cleanup();

			renderedCurrentState = false;
			currentState = null;
		}
		nextState = state;
		setScene(state);
	}

	override function update(dt) {
		final t1 = Timer.stamp();

		if (currentState != null) {
			try {
				currentState.update(dt);
			} catch (e) {
				currentState = null;
				trace("Error was thrown in update. Disabled GameState.");
				throw e;
			}
		}

		final updateTime = Timer.stamp() - t1;
		avgUpdateTime = smooth(avgUpdateTime, updateTime, 0.95);
	}

	inline function smooth(avg:Float, next:Float, alpha:Float) {
		return alpha * avg + (1 - alpha) * next;
	}

	override function render(engine:h3d.Engine) {
		if (currentState != null) {
			try {
				currentState.renderUpdate();
			} catch (e) {
				currentState = null;
				trace("Error was thrown in renderUpdate. Disabled GameState.");
				throw e;
			}
		}
		final t1 = Timer.stamp();
		super.render(engine);
		final renderTime = Timer.stamp() - t1;
		avgRenderTime = smooth(avgRenderTime, renderTime, 0.95);

		// Only initialize the next state once the previous cleanup state has been rendered.
		if (renderedCurrentState && nextState != null) {
			currentState = nextState;
			nextState = null;
			final stateClassName = Type.getClassName(Type.getClass(currentState));
			trace("Initializing state: " + stateClassName);
			currentState.init();
			trace("Number of objects: " + s2d.getObjectsCount());
		}
		renderedCurrentState = true;
	}

	public static function toggleFullScreen() {
		final window = hxd.Window.getInstance();
		switch (window.displayMode) {
			case Fullscreen | FullscreenResize | Borderless:
				window.displayMode = Windowed;
			case _:
				window.displayMode = FullscreenResize;
		}
	}
}
