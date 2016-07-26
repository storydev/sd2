package;

import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class Command
{

    private var _commandLine:String;
    
    public var type:String;
    public var outputDir:String;
    
    //Build variables
    public var useVerbose:Bool;
    public var includedCompilationOptions:Array<String>;
    
    //Create variables
    
    public function new(type:String, dir:String)
    {
        this.type = type;
        outputDir = dir;
        includedCompilationOptions = [];
    }
    
    public function build()
    {
        var path = Path.normalize(outputDir);
        var target = "";
        
        var resourceValues = [];
        
        if (FileSystem.exists(path + "/project.json"))
        {
            var contents:Dynamic = Json.parse(File.getContent(path + "/project.json"));
            if (contents.target == null || contents.output == null || contents.sourceFolder == null)
            {
                Sys.println("You are missing some standard data inside project.json");
            }
            
            target = contents.target;
            
            _commandLine = 'haxe -cp ${contents.sourceFolder} -main Main -${contents.target} ${contents.output} -lib sd2 -lib hscript';
            
            if (includedCompilationOptions.length > 0)
                _commandLine += includedCompilationOptions.join(" ") + ' ';
            
            if (contents.convos == null)
            {
                Sys.println("The `convos` field does not exist inside project.json.");
                return;
            }
            
            for (i in 0...contents.convos.length)
            {
                var file:String = contents.convos[i];
                
                if (useVerbose)
                    resourceValues.push(file);
                
                var fileName = file.substring(file.lastIndexOf('/') + 1, file.lastIndexOf('.'));
                
                _commandLine += '-resource "$file"@$fileName '; 
            }
        }
        else
        {
            Sys.println(path + "/project.json does not exist.");
        }
        
        if (useVerbose)
        {
            Sys.println(_commandLine);
            Sys.println("Resources used:");
            for (i in 0...resourceValues.length)
                Sys.println(resourceValues[i]);
            
            Sys.println('Target: $target');
        }
        
        Sys.command(_commandLine);
    }
    
}