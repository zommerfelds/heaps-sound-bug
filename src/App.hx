import h2d.Tile;
import h2d.Flow;

class App extends hxd.App {
	static function main() {
		new App();
	}

	override function init() {
		hxd.Res.initEmbed();

		final flow = new Flow(s2d);
		flow.x = 50;
		flow.y = 30;
		flow.backgroundTile = Tile.fromColor(0xff0000);
		flow.padding = 20;
		flow.enableInteractive = true;
		flow.interactive.onClick = e -> {
			trace("Playing sound");
			hxd.Res.blip.play();
		};

		final tf = new h2d.Text(hxd.res.DefaultFont.get(), flow);
		tf.scale(3);
		tf.text = "Bad file";

		final flow = new Flow(s2d);
		flow.x = 50;
		flow.y = 120;
		flow.backgroundTile = Tile.fromColor(0x00ff00);
		flow.padding = 20;
		flow.enableInteractive = true;
		flow.interactive.onClick = e -> {
			trace("Playing sound");
			hxd.Res.blip2.play();
		};

		final tf = new h2d.Text(hxd.res.DefaultFont.get(), flow);
		tf.scale(3);
		tf.text = "Good file";
	}
}
