package states;

@:structInit class KeyOutcome {
	@:optional public var enter:Void->Void;
	@:optional public var back:Void->Void;
	@:optional public var both:Void->Void;
}

class WarningState extends MusicBeatState
{
	var warnText:FlxText;
	var outcomes:KeyOutcome;
	public function new(title:String, text:String, outcomes:KeyOutcome, ?titleColor:FlxColor = -1) {
		super();
		
		var title = new objects.Alphabet(0, 0, title, true);
		for (letter in title.letters) letter.color = titleColor;
		title.screenCenter(X);
		add(title);

		warnText = new FlxText(0, 0, FlxG.width, text, 32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.applyMarkup(text, [
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFF7474), '<!>'),
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFEA74), '<?>'),
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF74FF84), '<*>'),
		]);
		warnText.screenCenter(Y);
		warnText.y += 50;
		add(warnText);

		title.y = warnText.y - title.height - 30;
		this.outcomes = outcomes;
	}

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		members.insert(0, bg);
	}

	override function update(elapsed:Float)
	{
		if (controls.ACCEPT) {
			outcomes?.enter(); outcomes?.both();
		}
		else if(controls.BACK) {
			outcomes?.back(); outcomes?.both();
		}

		super.update(elapsed);
	}
}
