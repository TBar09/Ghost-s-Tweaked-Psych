package hscript;

class Config {
	public static final ALLOWED_CUSTOM_CLASSES = ["flixel", "backend", "states", "substates", "shaders", "psychlua", "options", "objects", "cutscenes"];
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		"flixel",
		"openfl",
		"haxe.xml",
		"haxe.CallStack"
	];
	public static final DISALLOW_CUSTOM_CLASSES = [];
	public static final DISALLOW_ABSTRACT_AND_ENUM = [];
}