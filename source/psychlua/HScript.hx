package psychlua;

import hscript.Expr.Error;
import hscript.Expr;
import hscript.*;

import flixel.FlxG;
import flixel.util.FlxColor;
import psychlua.LuaUtils;
#if LUA_ALLOWED
import llua.Lua;
#end
#if sys
import sys.io.File;
#else
import openfl.utils.Assets;
#end

/*
 * HScript improved class. Originally made for T-Bar Psych Fork & modified for use in Ghost Engine
*/
interface HscriptInterface {
    public var scriptName:String;
    public function set(variable:String, data:Dynamic):Void;
    public function call(func:String, ?args:Array<Dynamic>):Dynamic;
    public function stop():Void;
}

class HScript implements HscriptInterface {

    public static var classes:Map<String, Dynamic> = [ //All the default classes
		//Haxe Classes
        "Math" => Math,
        "Std" => Std,
		"Type" => Type,
		"StringTools" => StringTools,
		"Reflect" => Reflect,

		//Flixel Classes
        "FlxG" => flixel.FlxG,
        "FlxSprite" => flixel.FlxSprite,
        "FlxTimer" => flixel.util.FlxTimer,
        "FlxTween" => flixel.tweens.FlxTween,
        "FlxEase" => flixel.tweens.FlxEase,
        "FlxText" => flixel.text.FlxText,
		#if sys
        "File" => sys.io.File,
        "FileSystem" => sys.FileSystem,
		#end

		//Friday Night Funkin' Classes
        "Paths" => backend.Paths,
        "Conductor" => backend.Conductor,
        "PlayState" => states.PlayState,
        "Boyfriend" => objects.Character, //compatibility
        "Character" => objects.Character,
		"CoolUtil"	=> backend.CoolUtil,
        "ClientPrefs" => backend.ClientPrefs,
		"MusicBeatState" => backend.MusicBeatState,
		"MusicBeatSubstate" => backend.MusicBeatSubstate,
		"Global" => backend.Global,

		//Classes in the root folder are pre-added so you don't have to do `import Main;`
		"Main" => Main,

		//Extras
		"Json" => { //Using the base haxe.Json library produces a null function pointer
			parse: function(txt:String):Dynamic { return haxe.Json.parse(txt); },
			stringify: function(value:Dynamic, ?replacer:(key:Dynamic, value:Dynamic) -> Dynamic, ?space:String) { return haxe.Json.stringify(value, replacer, space); }
		},
		"FlxBasic" => flixel.FlxBasic,
		"FlxCamera" => flixel.FlxCamera,
		"FlxSound" => flixel.sound.FlxSound, //Not like people will use the old flixel for flixel.sytem
		"FlxMath" => flixel.math.FlxMath,
		"FlxGroup" => flixel.group.FlxGroup,
		#if (!flash) "FlxRuntimeShader" => flixel.addons.display.FlxRuntimeShader, #end
		"ShaderFilter"	=> openfl.filters.ShaderFilter,

		//Extras with abstracts/enums
		"FlxPoint" => LuaUtils.getMacroAbstractClass("flixel.math.FlxPoint"),
		"FlxAxes" => LuaUtils.getMacroAbstractClass("flixel.util.FlxAxes"),
		"FlxColor" => LuaUtils.getMacroAbstractClass("flixel.util.FlxColor")
    ];
	public static var staticVariables:Map<String, Dynamic> = [];

    public var parser:Parser;
    public var interp:Interp;
    public var expr:Expr;
    public var scriptName:String;
	public var modFolder:String;

    public function new(path:String, _isHaxeCode:Bool = true) {
		if(!_isHaxeCode) return; //this field is only really used for runHaxeCode module

        if (parser == null) initializeModule("parser");
		if(interp == null) initializeModule("interp");
        scriptName = path;
		
		#if MODS_ALLOWED
		if (scriptName != null && scriptName.length > 0) {
			var myFolder:Array<String> = scriptName.trim().split('/');
			if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
				this.modFolder = myFolder[1];
		}
		#end

        try {
            parser.line = 1; //Reset the parser position.
            expr = parser.parseString(#if sys File.getContent(path) #else Assets.getText(path) #end, path);
			trace(path);

			interp.variables.set("this", this);

			for (key => value in classes) interp.variables.set(key, value);

            if (FlxG.state is PlayState) {
                interp.scriptObject = PlayState.instance;
				interp.publicVariables = PlayState.instance.variables;
            } else {
				interp.scriptObject = LuaUtils.getHScriptParent();

				//Prevents the game from printing a null obj reference if the script is added to a state with no variables map
				if(Reflect.field(interp.scriptObject, "variables") != null) 
					interp.publicVariables = interp.scriptObject.variables;
			}
			addHScriptFuncs(this.interp);

			//importScript is handled in state parent itself unlike T-Bar Engine
			//interp.variables.set('importScript', importScript);

			interp.variables.set("trace", hscriptTrace);
			interp.variables.set('getModSetting', function(saveTag:String, ?modName:String = null) {
				if(modName == null)
				{
					if(this.modFolder == null)
					{
						FunkinLua.luaTrace('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', true, false, 0xFFFF0000);
						return null;
					}
					modName = this.modFolder;
				}
				return LuaUtils.getModSetting(saveTag, modName);
			});

            interp.execute(expr);
            call("onCreate", []);
        } catch (e) {
            FlxG.stage.window.alert('Error on Haxe Script.\n${e.toString()}', 'Error on haxe script!');
        }
    }

	public static function addHScriptFuncs(obj:Interp) {
		if(obj == null) return;

		if(FlxG.state is PlayState) {
			obj.variables.set("game", PlayState.instance);

			obj.variables.set('add', PlayState.instance.insert);
			obj.variables.set('insert', PlayState.instance.insert);
			obj.variables.set('remove', PlayState.instance.remove);
			obj.variables.set('addBehindGF', PlayState.instance.addBehindGF);
			obj.variables.set('addBehindDad', PlayState.instance.addBehindDad);
			obj.variables.set('addBehindBF', PlayState.instance.addBehindBF);
			obj.variables.set('setVar', function(name:String, value:Dynamic) {
				PlayState.instance.variables.set(name, value);
				return value;
			});
			obj.variables.set('getVar', function(name:String) {
				var result:Dynamic = null;
				if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
				return result;
			});
			obj.variables.set('removeVar', function(name:String) {
				if(PlayState.instance.variables.exists(name)) {
					PlayState.instance.variables.remove(name);
					return true;
				}
				return false;
			});

			obj.variables.set('customSubstate', CustomSubstate.instance);
			obj.variables.set('customSubstateName', CustomSubstate.name);
		} else {
			obj.variables.set("game", obj.scriptObject);
			obj.variables.set('add', obj.scriptObject.add);
			obj.variables.set('insert', obj.scriptObject.insert);
			obj.variables.set('remove', obj.scriptObject.remove);

			if(obj.scriptObject.variables != null) {
				obj.variables.set('setVar', function(name:String, value:Dynamic) {
					obj.scriptObject.variables.set(name, value);
					return value;
				});
				obj.variables.set('getVar', function(name:String) {
					var result:Dynamic = null;
					if(obj.scriptObject.variables.get(name) != null) result = obj.scriptObject.variables.get(name);
					return result;
				});
				obj.variables.set('removeVar', function(name:String) {
					if(obj.scriptObject.variables.get(name) != null) {
						obj.scriptObject.variables.remove(name);
						return true;
					}
					return false;
				});
			}
		}

		//other variables
		obj.variables.set('Function_Stop', LuaUtils.Function_Stop);
		obj.variables.set('Function_Continue', LuaUtils.Function_Continue);
		obj.variables.set('Function_StopHScript', LuaUtils.Function_StopHScript);
		obj.variables.set('Function_StopLua', LuaUtils.Function_StopLua);
		obj.variables.set('Function_StopAll', LuaUtils.Function_StopAll);
		
		obj.variables.set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		obj.variables.set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		obj.variables.set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		obj.variables.set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		obj.variables.set('anyGamepadPressed', function(name:String) FlxG.gamepads.anyPressed(name));
		obj.variables.set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

		obj.variables.set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		obj.variables.set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		obj.variables.set('gamepadJustPressed', function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		obj.variables.set('gamepadPressed', function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		obj.variables.set('gamepadReleased', function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		obj.variables.set('keyJustPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT_P;
				case 'down': return Controls.instance.NOTE_DOWN_P;
				case 'up': return Controls.instance.NOTE_UP_P;
				case 'right': return Controls.instance.NOTE_RIGHT_P;
				default: return Controls.instance.justPressed(name);
			}
			return false;
		});
		obj.variables.set('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT;
				case 'down': return Controls.instance.NOTE_DOWN;
				case 'up': return Controls.instance.NOTE_UP;
				case 'right': return Controls.instance.NOTE_RIGHT;
				default: return Controls.instance.pressed(name);
			}
			return false;
		});
		obj.variables.set('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT_R;
				case 'down': return Controls.instance.NOTE_DOWN_R;
				case 'up': return Controls.instance.NOTE_UP_R;
				case 'right': return Controls.instance.NOTE_RIGHT_R;
				default: return Controls.instance.justReleased(name);
			}
			return false;
		});

		obj.variables.set("state", FlxG.state);
		obj.variables.set('buildTarget', LuaUtils.getBuildTarget());

		#if LUA_ALLOWED
		obj.variables.set("createGlobalCallback", function(name:String, func:Dynamic) {
			if(FlxG.state is PlayState) {
				for(script in PlayState.instance.luaArray) {
					if(script != null && script.lua != null && !script.closed) 
						Lua_helper.add_callback(script.lua, name, func);
				}
			}

			FunkinLua.customFunctions.set(name, func);
		});

		obj.variables.set("createCallback", function(name:String, func:Dynamic, ?lua:FunkinLua) {
			if(lua == null) {
				FunkinLua.luaTrace('createCallback: no script was found or 3rd argument was null!', true, false, 0xFFFF0000);
				return false;
			}

			lua.addLocalCallback(name, func);
			return true;
		});
		#end
	}
	
	//CALLBACKS FOR SCRIPT STUFF

    function hscriptTrace(v:Dynamic) {
		var posInfos = interp.posInfos();
		trace(posInfos.fileName + ":" + posInfos.lineNumber + ": " + Std.string(v));
    }

    function onError(e:Error) {
		FunkinLua.luaTrace(Printer.errorToString(e), true, false, 0xFFFF0000);
    }

	//BACKEND FUNCTIONS
	public function setPublicMap(map:Map<String, Dynamic>) {
		if(interp != null) interp.publicVariables = map;
		return this;
	}

	public function setParent(parent:Dynamic) {
		if(interp != null) interp.scriptObject = parent;
		return this;
	}

    public function initializeModule(toInit:String) {
		switch(toInit) {
			case "parser":
				parser = new hscript.Parser();
				parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
				parser.preprocessorValues = LuaUtils.hscriptPreprocessors;

			case "interp":
				interp = new Interp();
				interp.allowStaticVariables = interp.allowPublicVariables = true;
				interp.staticVariables = staticVariables;
				interp.errorHandler = onError;
		}
    }

	//SCRIPT CALLBACKS
	public function stop() {
        expr = null;
        interp = null;
		parser = null;
    }

	public function get(name:String)
		return interp.variables.get(name) ?? null;


	public function set(variable:String, data:Dynamic)
		if(interp != null) interp.variables.set(variable, data);

    public function call(func:String, ?args:Array<Dynamic>):Dynamic {
		if (interp == null) return null;

		var funcToRun = {func: interp.variables.get(func), hasArgs: (args != null && args.length > 0)};
        if (funcToRun.func == null || !Reflect.isFunction(funcToRun.func)) return null;
        return funcToRun.hasArgs ? Reflect.callMethod(null, funcToRun.func, args) : funcToRun.func();
    }
}

class HaxeCode extends HScript {
	public var parentLua:FunkinLua;

	public var variables(get, never):Map<String, Dynamic>;
	public function get_variables() return interp.variables;

	override public function new(?parent:FunkinLua) {
		super(null, false);

		if(parser == null) this.initializeModule("parser");
		if(interp == null) this.initializeModule("interp");

		interp.scriptObject = LuaUtils.getHScriptParent();

		for(key => value in HScript.classes) interp.variables.set(key, value);

		interp.variables.set('Alphabet', objects.Alphabet);
		interp.variables.set('CustomSubstate', psychlua.CustomSubstate);

		interp.variables.set('this', this);
		HScript.addHScriptFuncs(interp);

		this.parentLua = parent;
		interp.variables.set('parentLua', #if LUA_ALLOWED parent #else null #end);
		interp.variables.set('scriptName', #if LUA_ALLOWED parent.scriptName #else null #end);
	}

	public function execute(codeToRun:String):Dynamic {
		if(parser == null) this.initializeModule("parser");
		if(interp == null) this.initializeModule("interp");
		parser.line = 1;

		return interp.execute(parser.parseString(codeToRun, (parentLua != null ? '${parentLua.scriptName}:runHaxeCode' : 'hscript')));
	}

	public function executeFunction(func:String, ?args:Array<Dynamic> = null):Dynamic
		return this.call(func, args);

	public static function implement(funk:FunkinLua) {
		if(funk == null) return;

		funk.addLocalCallback("runHaxeCode", function(codeToRun:String):Dynamic {
			var returnVal:Dynamic = null;
			#if HSCRIPT_ALLOWED
			try {
				returnVal = funk.hscript.execute(codeToRun);
				if(returnVal != null)
					return (returnVal == null || LuaUtils.isOfTypes(returnVal, [Bool, Int, Float, String, Array])) ? returnVal : null;
			} catch (e:Dynamic) {
				FunkinLua.luaTrace('${funk.scriptName}:${funk.lastCalledFunction} - $e', false, false, FlxColor.RED);
			}
			#else
			FunkinLua.luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
			return returnVal;
		});

		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			#if HSCRIPT_ALLOWED
			var str:String = '';
			if(libPackage.length > 0) str = libPackage + '.';
			else if(libName == null) libName = '';

			var classObj:Dynamic = Type.resolveClass(str + libName);
			if(classObj == null) classObj = LuaUtils.getMacroAbstractClass(str + libName);
			if(classObj == null) classObj = Type.resolveEnum(str + libName);
			if(funk.hscript == null) return;

			try {
				if (classObj != null) funk.hscript.variables.set(libName, classObj);
			} catch(e:Dynamic) {
				FunkinLua.luaTrace('${funk.scriptName}:${funk.lastCalledFunction} - $e', false, false, FlxColor.RED);
			}

			#else
			FunkinLua.luaTrace("addHaxeLibrary: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			#if HSCRIPT_ALLOWED
			if(!funk.hscript.variables.exists(funcToRun)) {
				FunkinLua.luaTrace('${funk.scriptName}:${funk.lastCalledFunction} - Function "${funcToRun}" does not exist!', false, false, FlxColor.RED);
				return null;
			}

			try {
				var callValue = funk.hscript.executeFunction(funcToRun, funcArgs);
				return callValue;
			} catch(e:Dynamic) {
				FunkinLua.luaTrace('${funk.scriptName}:${funk.lastCalledFunction} - $e', false, false, FlxColor.RED);
			}
			#else
			FunkinLua.luaTrace("runHaxeFunction: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end

			return null;
		});
	}

	public function destroy() {
		expr = null;
        interp = null;
		parser = null;
	}
}