class App extends HerbalTeaApp {
	static function main() {
		new App();
	}

	override function onload() {
		switchState(new PlayView());
	}
}
