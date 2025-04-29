package backend;

import flixel.util.FlxSignal.FlxTypedSignal;

// made to be extended
class SelectableMenu extends MusicBeatState {
    var _bg:FlxSprite;
    public var curSelected:Array<Int> = [0, 0];
    public var scrollMult:Array<Float> = [0, 0];
    public var allowWrapping:Bool = true;
    public var lead:Int = 0;

    public var optionOrder:Array<String>;
    public var options:Map<String, Void->Void> = new Map();

    public var onEnterPressed:FlxTypedSignal<Void->Void>;
    public var onItemChanged:FlxTypedSignal<Void->Void>;

    public function new(options:KeyValueArray<Void->Void>, background:String) {
        super();

        optionOrder = options.keys;
        this.options = options.map;

        _bg = new FlxSprite().loadGraphic(Paths.image(background));
        _bg.antialiasing = ClientPrefs.data.antialiasing;
        add(_bg);

        onEnterPressed = new FlxTypedSignal<Void->Void>();
        onItemChanged = new FlxTypedSignal<Void->Void>();
    }

    override function create() super.create();
    override function update(elapsed:Float) {
        super.update(elapsed);
        
        if (controls.ACCEPT) {
            onEnterPressed.dispatch();
            trace('Pressed ENTER test');

            options.get(optionOrder[curSelected[lead]])();
        }

        if (controls.UI_UP_P || controls.UI_DOWN_P || controls.UI_LEFT_P || controls.UI_RIGHT_P) {
            final i = (controls.UI_UP_P || controls.UI_DOWN_P) ? 1 : 0;
            final delta = int( ((controls.UI_UP_P || controls.UI_RIGHT_P) ? 1 : -1) * scrollMult[i] );

            curSelected[i] += delta;
            if (allowWrapping)
                curSelected[i] %= optionOrder.length;
                if (curSelected[i] < 0) curSelected[i] = optionOrder.length-1;
            else
                curSelected[i] = FlxMath.wrap(curSelected[i], 0, optionOrder.length-1);

            onItemChanged.dispatch();
        }
    }
}

class KeyValueArray<T> {
    public var map:Map<String, T>;
    public var keys:Array<String>;
    public var values:Array<T>;

    public function new(keys:Array<String>, values:Array<T>) {
        if (keys.length == values.length) {
            var map:Map<String, T> = [];
            for (i => key in keys) map.set(key, values[i]);

            this.map = map;
            this.keys = keys;
            this.values = values;
        } else error('keys and values must be the same length!');
    }
}