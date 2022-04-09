import h2d.Tile;
import h2d.Flow;

class App extends hxd.App {
	static function main() {
		new App();
	}

	override function init() {
		hxd.Res.initEmbed();

		final flow = new Flow(s2d);
		flow.x = 100;
		flow.y = 100;
		flow.backgroundTile = Tile.fromColor(0xff0000);
		flow.padding = 20;
		flow.enableInteractive = true;
		flow.interactive.onClick = e -> {
			trace("Playing sound");
			hxd.Res.blip.play();
		};

		final tf = new h2d.Text(hxd.res.DefaultFont.get(), flow);
		tf.scale(3);
		tf.text = "Play!";
	}
}
