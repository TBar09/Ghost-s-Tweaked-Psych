package backend;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class Macro {
	//From Codename Engine
	public static var compilerDefines(get, null):Map<String, Dynamic>;
	private static inline function get_compilerDefines() return __getDefines();
	private static macro function __getDefines() {
		#if display
		return macro $v{[]};
		#else
		return macro $v{Context.getDefines()};
		#end
	}
	
	//Adds any extra classes into the executable, no dce
	public static final addonClasses:Array<String> = [
		"backend"
	];

	@:unreflective public static function compileMacros() {
		#if macro
		//doing this since using `#if 32bits` throws an error
		if(Context.defined("32bits"))
			Compiler.define("x86_BUILD", "1");

		for(classPackage in addonClasses) Compiler.include(classPackage);
		#end
	}
}