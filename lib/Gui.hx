import haxe.ValueException;

class Gui {
	public static function scale(multiplier = 1.0) {
		var normWidth:Float = hxd.Window.getInstance().width;
		if (hxd.Window.getInstance().width / hxd.Window.getInstance().height > 9 / 16) {
			normWidth = 9 / 16 * hxd.Window.getInstance().height;
		}
		return normWidth / 600 * multiplier;
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
