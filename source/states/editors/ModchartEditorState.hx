package states.editors;

import flixel.group.FlxGroup.FlxTypedGroup;

import objects.StrumNote;
import backend.BaseStage;
import states.stages.StageWeek1 as BackgroundStage;
import states.PlayState;

class ModchartEditorState extends MusicBeatState {
    var camGame:FlxCamera;
    var camHUD:FlxCamera;

    var stage:BaseStage;

    var playerStrums:FlxTypedGroup<StrumNote>;
    var opponentStrums:FlxTypedGroup<StrumNote>;
    var strumLineNotes:FlxTypedGroup<StrumNote>;

    var downScroll:Bool = false;
    var middleScroll:Bool = false;

    public function new() super();

    override function create() {
        super.create();

        add(playerStrums = new FlxTypedGroup<StrumNote>());
        add(opponentStrums = new FlxTypedGroup<StrumNote>());
        add(strumLineNotes = new FlxTypedGroup<StrumNote>());

        FlxG.cameras.setDefaultDrawTarget(FlxG.camera, false);

        camGame = new FlxCamera();
        camGame.zoom = 0.6;
        camGame.scroll.set(-10, 0);
        FlxG.cameras.add(camGame, true);

        Paths.setCurrentLevel('week1');
        stage = new BackgroundStage();
        add(stage);

        camHUD = new FlxCamera();
        camHUD.bgColor = 0x0;
        FlxG.cameras.add(camHUD, false);

        camGame.flashSprite.scaleX = camHUD.flashSprite.scaleX = camGame.flashSprite.scaleY = camHUD.flashSprite.scaleY = 0.45;
        camGame.y = camHUD.y = -200;

        setupStrums();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
    }

    function setupStrums() {
        for (i in 0...8) {
            var strumX:Float = middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
		    var strumY:Float = downScroll ? (FlxG.height - 150) : 50;

            final player = Math.floor(i/4);
            var strum = new StrumNote(strumX, strumY, i%4, player);
            strum.camera = camHUD;

            if (player == 1) playerStrums.add(strum);
            else {
                if (middleScroll) {
                    strum.x += 310;
				    if (i > 1) strum.x += FlxG.width / 2 + 25;
                }
                opponentStrums.add(strum);
            }

            strumLineNotes.add(strum);
            strum.postAddedToGroup();
        }
    }
}