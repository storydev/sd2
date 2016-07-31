package;
import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

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
        var convos = new Array<String>();
        
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
                
                for (i in 0...convos.length)
                {
                    var filePath:String = convos[i];
                    var fileName:String = changePath(filePath);
                    
                    commandLine += '-resource $filePath@$fileName\n';
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
        }
    }
    
    private static function changePath(str:String)
    {
        if (Sys.systemName() == "Windows" && str.indexOf('\\') > -1)
            return str.substring(str.lastIndexOf('\\') + 1, str.lastIndexOf('.'));
        else
            return str.substring(str.lastIndexOf('/') + 1, str.lastIndexOf('.'));
    }
    
}