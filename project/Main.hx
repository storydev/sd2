package;
import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class Main
{

    public static function main()
    {
        var args = Sys.args();
        var dir:String = args[args.length - 1];
        dir = dir.substring(0, dir.length - 1);
        trace(dir);
        
        var _application_path = Sys.getCwd();
        var command = new Command(args[0], dir);
        
        trace(args);
        
        Sys.setCwd(dir);
        
        if (command.type == "build")
        {
            for (i in 1...args.length)
            {
                switch (args[i])
                {
                    case "-v":
                        command.useVerbose = true;
                    case "-D":
                        command.includedCompilationOptions.push(args[i]);
                        command.includedCompilationOptions.push(args[i + 1]);
                }
            }
            
            command.build();
        }
    }
    
}