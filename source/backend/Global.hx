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
        modVersion = '0.0.0';
        forkVersion = '0.0.1';
        forkStage = 'alpha';

        var toPrint:String = 'Application Meta: {';
        for (key => field in Application.current.meta) {
            toPrint += '\n    $key: $field';
        }
        trace(toPrint + '\n}');

        var http = new haxe.Http("https://raw.githubusercontent.com/GhostglowDev/Ghost-s-Tweaked-Psych/main/forkVersion.txt");
        http.onData = function(data:String)
        {
            forkLatestVersion = data.split('\n')[0].trim();
            trace('Latest Version: ' + forkLatestVersion + ', Current Version: ' + forkVersion);
            if(forkLatestVersion != forkVersion) {
                trace('Versions does not match.');
                states.TitleState.mustUpdate = true;
            }
        }

        http.onError = function (error) {
            trace('ERROR: $error');
        }

        http.request();
    }

    static function get_modVersion():String {
        return Mods.getPack()?.version ?? '0.0.0';
    }
}