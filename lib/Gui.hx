import haxe.Timer;
import haxe.ValueException;

class Gui {
	public static function scale(multiplier = 1.0) {
		var normWidth:Float = hxd.Window.getInstance().width;
		if (hxd.Window.getInstance().width / hxd.Window.getInstance().height > 9 / 16) {
			normWidth = 9 / 16 * hxd.Window.getInstance().height;
		}
		return normWidth / 600 * multiplier;
	};

	public static function scaleAsInt(multiplier = 1.0) {
		return Std.int(scale(multiplier));
	};
}

class Text extends h2d.HtmlText {
	// Small hack to get spaces to work in HtmlText.
	public static final SPACE = "<b> </b>";

	public function new(text, ?parent, size = 1.0, addDefaultShadow = false) {
		final fontRes = hxd.Res.Catamaran_Light_sdf;
		final font = fontRes.toSdfFont(Std.int(size * Gui.scale(60)), Alpha);
		super(font, parent);
		this.text = text;
		smooth = true;
		textColor = 0xffffffff;

		// Reduce space between lines. This may need to change depending on the font.
		lineSpacing = -font.lineHeight * 0.2;

		if (addDefaultShadow) {
			dropShadow = {
				dx: Gui.scale(5),
				dy: Gui.scale(5),
				color: 0x000000,
				alpha: 0.5
			};
		}
	}

	override function set_text(newText:String) {
		try {
			super.set_text(newText);
		} catch (e:ValueException) {
			// There may be XML parse issues. Better this than to crash the app.
			trace(e);
			super.set_text("PARSE ERROR");
		}
		return newText;
	}
}

class Colors {
	public static final BLUE = 0xff352fad;
	public static final GREEN = 0xff469129;
	public static final RED = 0xffb55f19;
	public static final GREY = 0xff444444;
	public static final LIGHT_GREY = 0xff666666;
}

class Button extends h2d.Object {
	public var enabled(default, set):Bool = true;

	// Need to call redrawButton() if the content size changes.
	public final content:h2d.Flow;

	final buttonShadow = new h2d.Graphics();
	final buttonShape = new h2d.Graphics();

	final shadowOffsetX:Float;
	final shadowOffsetY:Float;

	public var backgroundColor(default, set):Int;

	public function new(parent, onClickFn:Void->Void, ?backgroundColor:Int, disableOnClick = false) {
		super(parent);

		if (backgroundColor == null)
			backgroundColor = Colors.LIGHT_GREY;

		final horizontalPadding = 20 * Gui.scale();
		final verticalPadding = 20 * Gui.scale();

		shadowOffsetX = 5 * Gui.scale();
		shadowOffsetY = 5 * Gui.scale();
		final buttonOffsetXPressed = shadowOffsetX * 0.5;
		final buttonOffsetYPressed = shadowOffsetY * 0.5;

		this.addChild(buttonShadow);
		this.addChild(buttonShape);

		var pushed = false;
		var pushTime:Null<Float> = null;
		var minReleaseTime = 0.15;
		content = new h2d.Flow(this);
		content.enableInteractive = true;
		content.paddingHorizontal = Std.int(horizontalPadding);
		content.paddingVertical = Std.int(verticalPadding);
		content.verticalAlign = Middle;
		content.interactive.onClick = (e) -> {
			e.propagate = false;
			if (!enabled)
				return;
			if (disableOnClick) {
				enabled = false;
			}
			onClickFn();
		};
		content.interactive.onPush = (e) -> {
			e.propagate = false;
			if (!enabled || pushed)
				return;
			pushed = true;
			// Sound.playButtonPush();
			pushTime = Timer.stamp();

			buttonShape.x += buttonOffsetXPressed;
			buttonShape.y += buttonOffsetYPressed;
			content.x += buttonOffsetXPressed;
			content.y += buttonOffsetXPressed;
		};
		function releaseButton(e) {
			e.propagate = false;
			if (!enabled || !pushed)
				return;
			pushed = false;
			final releaseTime = Timer.stamp();
			final sleepTime = Math.max(0.0, minReleaseTime - (releaseTime - pushTime));
			// Timer.delay(Sound.playButtonRelease, Std.int(1000 * sleepTime));
			pushTime = null;

			buttonShape.x -= buttonOffsetXPressed;
			buttonShape.y -= buttonOffsetYPressed;
			content.x -= buttonOffsetXPressed;
			content.y -= buttonOffsetXPressed;
		}
		content.interactive.onRelease = releaseButton;
		content.interactive.onOut = releaseButton;

		// This will also render the button.
		this.backgroundColor = backgroundColor;
	}

	function set_backgroundColor(color) {
		backgroundColor = color;
		redrawButton();
		return backgroundColor;
	}

	// Users or subclasses must call this function if they change the content.
	// There is maybe a better way to do this with contentChanged, but meh.
	public function redrawButton() {
		final w = content.outerWidth == 0 ? Std.int(Gui.scale() * 100) : content.outerWidth;
		final h = content.outerHeight == 0 ? Std.int(Gui.scale() * 100) : content.outerHeight;

		buttonShadow.clear();
		buttonShadow.beginFill(0x000000, 0.5);
		buttonShadow.drawRoundedRect(0, 0, w, h, 10 * Gui.scale());
		buttonShadow.x = shadowOffsetX;
		buttonShadow.y = shadowOffsetY;

		buttonShape.clear();
		buttonShape.beginFill(backgroundColor);
		buttonShape.drawRoundedRect(0, 0, w, h, 10 * Gui.scale());
	}

	function set_enabled(enabled) {
		return this.enabled = enabled;
	}
}

class TextButton extends Button {
	static final BUTTON_TEXT_COLOR_ENABLED = 0xffffffff;
	static final BUTTON_TEXT_COLOR_DISABLED = 0xffaaaaaa;

	var text:h2d.Text;

	public var labelText(get, set):String;

	public function new(parent, labelText:String, onClickFn:Void->Void, backgroundColor = 0xff0000, disableOnClick = false, textSize = 1.0, maxWidth = null) {
		super(parent, onClickFn, backgroundColor, disableOnClick);

		text = new Text(labelText, content, textSize);
		text.textAlign = MultilineCenter;
		if (maxWidth != null) {
			text.maxWidth = maxWidth;
		}

		// Remove some space from top (lineSpacing is usually negative).
		content.paddingTop += Std.int(text.lineSpacing);

		redrawButton();
	}

	override function set_enabled(enabled) {
		text.textColor = enabled ? BUTTON_TEXT_COLOR_ENABLED : BUTTON_TEXT_COLOR_DISABLED;
		return super.set_enabled(enabled);
	}

	function get_labelText() {
		return text.text;
	}

	function set_labelText(t) {
		final r = (text.text = t);
		redrawButton();
		return r;
	}
}
