package;
import haxe.Json;
import haxe.Template;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

import massive.sys.io.File in MFile;

using StringTools;

class Main
{

    public static function main()
    {
        var args = Sys.args();
        var dir:String = args[args.length - 1];
        
        var useVerbose = false;
        var includedCompilationOptions = new Array<String>();
        var _application_path = Sys.getCwd();
        var _source_folder = "./";
        
        Sys.setCwd(dir);
        
        for (i in 1...args.length)
        {
            switch (args[i])
            {
                case "-v":
                    useVerbose = true;
                    includedCompilationOptions.push(args[i]);
                case "-D":
                    includedCompilationOptions.push(args[i] + " " + args[i + 1]);
                default:
                    if (args[i].startsWith('-'))
                        includedCompilationOptions.push(args[i]);
            }
        }
        
        var commandLine:String = "";
        var convos:Dynamic = {};
        
        if (args[0] == "build")
        {
            if (FileSystem.exists(dir + "/project.json"))
            {
                var data:Dynamic = Json.parse(File.getContent(dir + "/project.json"));
                
                var target:String = data.target;
                var output:String = FileSystem.absolutePath(data.output);
                
                convos = data.convos;
                
                if (data.source != null)
                {
                    if (data.source == "./")
                        _source_folder = dir;
                    else
                        _source_folder = FileSystem.absolutePath(data.source);
                }
                else
                    _source_folder = dir;
                
                commandLine = '-cp "$_source_folder"\n -main Main\n -$target "$output"\n -lib sd2\n -lib hscript\n';
                
                if (Std.is(convos, String))
                {
                    var files = MFile.create(forceBackslash(FileSystem.absolutePath(convos))).getRecursiveDirectoryListing(new EReg(".sdc", ""));
                    
                    for (i in 0...files.length)
                    {
                        var filePath:String = files[i].nativePath;
                        var fileName:String = changePath(filePath);
                        fileName = fileName.replace(" ", "_");
                        
                        commandLine += '-resource $filePath@$fileName\n';
                    }
                }
                else
                {
                    for (i in 0...convos.length)
                    {
                        var filePath:String = convos[i];
                        var fileName:String = changePath(filePath);
                        fileName = fileName.replace(" ", "_");
                        
                        commandLine += '-resource $filePath@$fileName\n';
                    }
                }
                
                commandLine += includedCompilationOptions.join(' ') + '\n';
                
                File.saveContent("build.hxml", commandLine);
            }
            
            if (useVerbose)
            {
                Sys.println("Resources used: ");
                for (i in 0...convos.length)
                    Sys.println(convos[i]);
            }
            
            Sys.println("Starting build...");
            
            Sys.command("haxe", ["build.hxml"]);
            Sys.println("Build successful.");
        }
        else if (args[0] == "create")
        {
            var folderName = args[1];
            var template = args[2];
            
            FileSystem.createDirectory(folderName);
            Sys.setCwd(Sys.getCwd() + "/" + folderName);
            
            var folder:MFile = MFile.create(Sys.getCwd());
            var _new_assets_folder:MFile = MFile.create(Sys.getCwd() + "/assets");
            var _assets:MFile = MFile.create(_application_path + "/templates/assets");
            
            switch (template)
            {
                case "js":
                    var js_template = _application_path + "/templates/js";
                    var _original:MFile = MFile.create(js_template);
                    
                    Sys.println("Copying template files...");
                    _original.copyTo(folder);
                    
                    var t = new Template(File.getContent("index.html"));
                    File.saveContent("index.html", t.execute({ game_title: folderName }));
                    
                    _assets.copyTo(_new_assets_folder);
                    Sys.println("Project created successfully.");
            }
        }
        else if (args[0] == "update")
        {
            Sys.println("The update process will copy new source code files and overwrite existing ones in this folder. Are you sure you want to continue? [Y - Yes | N - No]\n");
            
            var char = Sys.stdin().readLine();
            if (char.toLowerCase().indexOf("y") == -1)
            {
                Sys.println("Update cancelled.");
                return;
            }
            
            var projectFile = Sys.getCwd() + "/project.json";
            if (FileSystem.exists(projectFile))
            {
                var src = MFile.create(Sys.getCwd() + "/src");
                var _origin_src:MFile = null;
                
                var target:String = Json.parse(File.getContent(projectFile)).target;
                switch (target)
                {
                    case "js":
                        Sys.println("Updating source files...");
                        _origin_src = MFile.create(_application_path + "/templates/js/src");
                        _origin_src.copyTo(src);
                        Sys.println("Update successful.");
                }
            }
        }
    }
    
    private static function forceBackslash(path:String):String
    {
        if (Sys.systemName() == "Windows")
            return path.replace("/", "\\");
        else
            return path;
    }
    
    private static function changePath(str:String)
    {
        if (Sys.systemName() == "Windows" && str.indexOf('\\') > -1)
            return str.substring(str.lastIndexOf('\\') + 1, str.lastIndexOf('.'));
        else
            return str.substring(str.lastIndexOf('/') + 1, str.lastIndexOf('.'));
    }
    
    private static function searchFolder(folder:String):Array<String>
    {
        var results = new Array<String>();
        
        var files = FileSystem.readDirectory(folder);
        for (f in files)
        {
            if (FileSystem.isDirectory(f))
                results = results.concat(searchFolder(f));
            else
            {
                if (f.endsWith(".sdc"))
                    results.push(f);
            }
        }
        
        return results;
    }
    
}