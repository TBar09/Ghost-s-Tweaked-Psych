package backend;

import lime.app.Application;

class Global {
    // Versions
    public static var fnfVersion(default, null):String;
    public static var engineVersion(default, null):String;
    public static var modVersion(get, null):String;
    public static var forkVersion(default, null):String;
    public static var forkLatestVersion(default, null):String;
    public static var forkStage(default, null):String;

    public static function init() {
        fnfVersion = Application.current.meta.get('version');
        engineVersion = '0.7.3';
        forkVersion = '0.0.1';
        forkStage = 'alpha';

        var http = new haxe.Http("https://raw.githubusercontent.com/AlsoGhostglowDev/Ghost-s-Tweaked-Psych/main/forkVersion.txt");
        http.onData = function(data:String)
        {
            forkLatestVersion = data.split('\n')[0].trim();
            trace('Latest Version: ' + forkLatestVersion + ', Current Version: ' + forkVersion);
            if(forkLatestVersion != forkVersion) {
                trace('Current version is outdated.');
                states.TitleState.mustUpdate = true;
            }
        }
        http.onError = function (error) {
            trace('HTTP: $error');
        }
        http.request();

        var toPrint:String = 'Application Meta: {';
        for (key => field in Application.current.meta) {
            toPrint += '\n    $key: $field';
        }
        trace(toPrint + '\n}');
    }

    static function get_modVersion():String {
        return Mods.getPack()?.version ?? '0.0.0';
    }
}