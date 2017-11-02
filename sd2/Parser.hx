package sd2;

import haxe.Constraints.Function;
import haxe.Resource;
import haxe.Template;
import js.Lib;
import js.Browser;
import hscript.Parser in HParser;
import hscript.Interp;
import hscript.Expr.Error;

#if twinspire
import twinspire.Application;
#end

#if kha
import kha.Assets;
import kha.Blob;
#end

using sd2.CommandType;
using StringTools;

class Parser
{

    private var _blocks:Array<CommandBlock>;
    private var _commands:Array<Command>;
    private var _interp:Interp;
    private var _parser:HParser;
    private var isAChoice:Bool;
    private var choices:Array<String>;
    private var currentBlock:CommandBlock;
    private var addedResources:Array<String>;
    
    private var _AutomaticNext:Bool;
    public var AutomaticNext(get, null):Bool;
    function get_AutomaticNext() return _AutomaticNext;
    
    public var variables(get, null):Map<String, Dynamic>;
    function get_variables() return _interp.variables;
    
    public function new(interp:Interp, parser:HParser)
    {
        Command.GLOBAL_ID = 0;
        
        _blocks = [];
        _commands = [];
        addedResources = [];
        
        _AutomaticNext = true;
        
        _interp = interp;
        _parser = parser;
    }
    
    public function parseFile(file:String)
    {
        #if twinspire
        var _index = Application.resources.loadMisc(file);
        var _file:Blob = Application.resources.misc[_index];

        var content = _file.readUtf8String();
        #elseif kha
        var _file:Blob = Reflect.field(Assets.fonts, file);

        var content = _file.readUtf8String();
        #else
        var content = Resource.getString(file);

        #end
        var lines = content.split("\n");
        currentBlock = null;
        isAChoice = false;
        choices = [];
        
        for (i in 0...lines.length)
        {
            var line:String = lines[i];
            
            if (line.startsWith("require"))
            {
                var pattern = ~/"([^"]+)"/;
                if (pattern.match(line))
                {
                    var res = pattern.matched(1);
                    if (!addRequiredResource(res))
                        parseFile(res);
                }
            }
        }
        
        for (i in 0...lines.length)
        {
            var line:String = lines[i];
            if (line == "" || line == "\r")
                continue;
            
            if (line.startsWith("char"))
            {
                var values = [];
                var pattern = ~/"([^"]+)" #([0-9A-Fa-f]+)/;
                if (pattern.match(line))
                {
                    values.push(pattern.matched(1));
                    values.push(pattern.matched(2));
                }
                else
                {
                    printError('$file : line $i : The character definition is in the wrong format.');
                }
                
                trace(values);
                _commands.push(Command.createCharacterCommand(values[0], values[1]));
            }
            else if (line.startsWith("convo"))
            {
                checkChoices();
                
                var value = "";
                var extraData = new Array<String>();
                var pattern = ~/"([^"]+)"/;
                if (pattern.match(line))
                {
                    value = pattern.matched(1);
                }
                else
                {
                    printError('$file : line $i : The block definition title must be wrapped in speech marks.');
                }
                
                var extraDataPattern = ~/\((("([^"]*)")(,*)[^\)]+)\)/;
                if (extraDataPattern.match(line))
                {
                    var values = extraDataPattern.matched(1).split(",");
                    for (s in values)
                    {
                        if (pattern.match(s))
                            extraData.push(pattern.matched(1));
                    }
                }
                
                if (currentBlock != null)
                    _blocks.push(currentBlock);
                
                currentBlock = new CommandBlock();
                currentBlock.id = Command.GLOBAL_ID++;
                currentBlock.resourceOrigin = file;
                currentBlock.title = value;
                currentBlock.extraData = extraData;
            }
            else if (line.startsWith("~"))
            {
                checkChoices();
                
                if (currentBlock != null)
                {
                    currentBlock.commands.push(Command.createOverlayTitle(line.substr(2)));
                }
                else
                {
                    printError('$file : line $i : Overlay titles must be placed within a conversation.');
                }
            }
            else if (line.startsWith(">"))
            {
                isAChoice = true;
                if (currentBlock != null)
                {
                    if (choices.length < 3)
                    {
                        var pattern = ~/([^\->]+) -> "([^"]+)"/;
                        var value = "";
                        
                        if (pattern.match(line))
                        {
                            value = pattern.matched(1) + "," + pattern.matched(2);
                        }
                        
                        choices.push(value);
                    }
                    else
                    {
                        printError('$file : line $i : You may not have any more than 3 adjacent choices.');
                    }
                }
                else
                {
                    printError('$file : line $i : Choices must be placed within a conversation.');
                }
            }
            else if (line.startsWith("="))
            {
                if (currentBlock != null)
                {
                    var value = line.substr(line.indexOf(' ') + 1);
                    if (value.indexOf("EXCLUSIVE") > -1)
                        currentBlock.isExclusive = true;
                    else if (value.indexOf("NOCLEAR") > -1)
                        currentBlock.clearCurrent = false;
                }
            }
            else if (line.startsWith("goto"))
            {
                checkChoices();
                
                if (currentBlock != null)
                {
                    var pattern = ~/"([^"]+)"/;
                    var title = "";
                    if (pattern.match(line))
                    {
                        title = pattern.matched(1);
                    }
                    
                    currentBlock.commands.push(Command.createNewConvo(title));
                }
                else
                {
                    printError('$file : line $i : Goto conversation markers ("::") must be placed within a conversation.');
                }
            }
            else if (line.startsWith(":"))
            {
                checkChoices();
                
                if (currentBlock != null)
                {
                    currentBlock.commands.push(Command.createNarrative(line.substr(2)));
                }
                else
                {
                    printError('$file : line $i : Narrative must be placed within a conversation.');
                }
            }
            else if (line.startsWith("__"))
            {
                checkChoices();
                
                if (currentBlock != null)
                {
                    var name = line.substring(2, line.indexOf(' '));
                    var text = line.substr(name.length + 4);
                    currentBlock.commands.push(Command.createInternalDialogue(name, text));
                }
            }
            else if (line.startsWith("!"))
            {
                checkChoices();
                
                if (currentBlock != null)
                {
                    var code = line.substr(2);
                    var parsed = parseCode(code);
                    if (parsed == "")
                    {
                        currentBlock.commands.push(Command.createCodeLine(code));
                    }
                }
                else
                {
                    printError('$file : line $i : Code lines must be parsed and executed within a conversation.');
                }
            }
            else
            {
                checkChoices();
                
                var pattern = ~/([^:]+) : (.+)/;
                var values = [];
                if (pattern.match(line))
                {
                    values.push(pattern.matched(1));
                    values.push(pattern.matched(2));
                }
                
                var firstValue:String = line.split(' ')[0];
                
                if (values == [])
                {
                    printError('$file : line $i : Unexpected "$firstValue" at the start of this line.');
                    continue;
                }
                
                if (currentBlock != null)
                {
                    currentBlock.commands.push(Command.createDialogue(values[0], values[1]));
                }
                else
                {
                    printError('$file : line $i : Dialogue must be placed within a conversation.');
                }
            }
            
            if (i == lines.length - 1)
            {
                if (currentBlock != null)
                {
                    checkChoices();
                    _blocks.push(currentBlock);
                }
            }
        }
    }
    
    /**
     * Returns true if the resource already exists.
     * @param resource
     * @return
     */
    private function addRequiredResource(resource:String):Bool
    {
        for (r in addedResources)
        {
            if (r == resource)
                return true;
        }
        addedResources.push(resource);
        return false;
    }
    
    private function checkChoices()
    {
        if (isAChoice && currentBlock != null)
        {
            currentBlock.commands.push(Command.createChoices(choices[0] != null ? choices[0] : "",
                                            choices[1] != null ? choices[1] : "",
                                            choices[2] != null ? choices[2] : ""));
            isAChoice = false;
            choices = [];
        }
    }
    
    private function parseCode(code:String)
    {
        try
        {
            var exec = _parser.parseString(code);
            return "";
        }
        catch (msg:Error)
        {
            processScriptError(msg);
            return "error";
        }
    }
    
    /**
     * Execute the given code.
     * @param code  The code to execute.
     */
    public function executeCode(code:String)
    {
        try
        {
            var exec = _parser.parseString(code);
            _interp.execute(exec);
            
            if (_interp.variables.exists("auto"))
                _AutomaticNext = _interp.variables.get("auto");
        }
        catch (msg:Error)
        {
            processScriptError(msg);
        }
    }
    
    private function processScriptError(msg:Error)
    {
        #if hscriptPos
        var error = 'Error (${msg.pmin} - ${msg.pmax}): ';
        var _msg = msg.e;
        #else
        var error = 'Error: ';
        var _msg = msg;
        #end
        
        switch (_msg)
        {
            case EInvalidChar(c):
                error += 'Invalid character ' + String.fromCharCode(c) + '.';
            case EUnexpected(s):
                error += 'Was not expecting $s.';
            case EUnterminatedString:
                error += 'String has not been terminated.';
            case EUnterminatedComment:
                error += 'Multiline comment has not been terminated.';
            case EUnknownVariable(v):
                error += 'The variable $v could not be found.';
            case EInvalidIterator(v):
                error += 'The loop $v is invalid.';
            case EInvalidOp(op):
                error += 'The operator $op is invalid.';
            case EInvalidAccess(f):
                error += 'Do not have access to $f.';
        }
        
        
        printError(error);
    }
    
    /**
     * Parses the narrative and returns the evaluated result.
     * @param value     The value of the narrative.
     */
    public function parseNarrative(value:String)
    {
        var result = "";
        var template = new Template(value);
        var d:Dynamic = {};
        for (key in _interp.variables.keys())
        {
            var value:Dynamic = _interp.variables.get(key);
            if (key != "true" && key != "false" && key != "null" && key != "trace" && !Reflect.isFunction(value))
                Reflect.setField(d, key, value);
        }
        
        return template.execute(d);
    }
    
    /**
     * Get all the characters defined in the file as commands.
     */
    public function getCharacters()
    {
        var commands = new Array<Command>();
        for (i in 0..._commands.length)
        {
            var cm = _commands[i];
            if (cm.type == CHARACTER)
            {
                commands.push(cm);
            }
        }
        return commands;
    }
    
    /**
     * Get a block of commands by the given title. The title of a block is denoted by a '$' sign.
     * @param title     The title to look for.
     */
    public function getBlockByTitle(title:String)
    {
        for (i in 0..._blocks.length)
        {
            if (_blocks[i].title == title)
                return _blocks[i];
        }
        return null;
    }
    
    /**
     * Parses the text, finding dollar signs ($) and converting their respective variable names to their values.
     * @param text  The text to parse.
     * @return      Returns the parsed text.
     */
    public function parseText(text:String):String
    {
        var replaced:String = text;
        var ignoredDollarSignInterval = 0;
        
        for (i in 0...text.length)
        {
            if (ignoredDollarSignInterval > 0)
                ignoredDollarSignInterval--;
            
            if (text.charAt(i) == "\\")
            {
                if (text.charAt(i + 1) == "$")
                    ignoredDollarSignInterval = 2;
                
                replaced = StringTools.replace(replaced, "\\", "");
            }
            else if (text.charAt(i) == "$" && ignoredDollarSignInterval == 0)
            {
                if ((text.charCodeAt(i + 1) > 64 && text.charCodeAt(i + 1) < 91)
                    || (text.charCodeAt(i + 1) > 96 && text.charCodeAt(i + 1) < 123))
                {
                    var field = getStringValue(text, i + 1);
                    
                    if (_interp.variables.exists(field))
                    {
                        replaced = StringTools.replace(replaced, "$" + field, _interp.variables.get(field));
                    }
                    else
                    {
                        var result = "The field '" + field + "' could not be parsed or found.";
                        printError(result);
                    }
                }
            }
        }
        return replaced;
    }
        
    private function getStringValue(text:String, startIndex:Int):String
    {
        var result = "";
        for (i in 0...text.length)
        {
            if (!validKeyCode(text.charCodeAt(i + startIndex)))
                break;
            
            result += text.charAt(i + startIndex);
        }
        return result;
    }
    
    private function validKeyCode(charCode:Int):Bool
    {
        return ((charCode > 64 && charCode < 91)
                || (charCode > 96 && charCode < 123) || (charCode == 95)
                || (charCode > 47 && charCode < 58));
    }
    
    public function getBlockById(id:Int)
    {
        for (i in 0..._blocks.length)
        {
            if (_blocks[i].id == id)
                return _blocks[i];
        }
        return null;
    }
    
    private function printError(error:String)
    {
        #if js
        Browser.console.error(error);
        #elseif sys
        Sys.stderr().writeString(error);
        #else
        trace(error);
        #end
    }
    
}