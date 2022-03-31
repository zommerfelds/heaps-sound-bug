class App extends HerbalTeaApp {
	public static var instance:App;

	static function main() {
		instance = new App();
	}

	override function onload() {
		switchState(new MenuView());
	}
}
