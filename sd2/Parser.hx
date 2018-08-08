package sd2;

import haxe.Constraints.Function;
import haxe.Resource;
import haxe.Template;
#if js
import js.Lib;
import js.Browser;
#end

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
    private var isAChoice:Bool;
    private var isDialogueBlock:Bool;
    private var choices:Array<String>;
    private var currentBlock:CommandBlock;
    private var addedResources:Array<String>;
    
    public function new()
    {
        Command.GLOBAL_ID = 0;
        
        _blocks = [];
        _commands = [];
        addedResources = [];
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
        isDialogueBlock = false;

        choices = [];
        var convo = false;
        var character = false;
        var overlay = false;
        var text = "";
        var narration = false;
        var dialogue = false;
        var charName = "";
        var choiceText = "";
        var choiceInstruction = "";
        var optionText = "";
        var option = false;

        for (i in 0...lines.length)
        {
            var line:String = lines[i];

            if (i == lines.length - 1)
            {
                if (currentBlock != null)
                {
                    checkChoices();
                    _blocks.push(currentBlock);
                }
            }

            if (line == "" || line == "\r")
                continue;
            
            if (line.endsWith("\r"))
                line = line.substr(0, line.length - 1);

            var value = line;
            var data = getNextWord(value);
            var word = data.word;
            var first = true;
            var arrow = false;
            while (word != "")
            {
                switch (word)
                {
                    case ">":
                    {
                        if (first)
                        {
                            isAChoice = true;
                        }
                    }
                    case "->":
                    {
                        if (isAChoice)
                        {
                            arrow = true;
                        }
                    }
                    case "=":
                    {
                        option = true;
                    }
                    case "convo":
                    {
                        convo = true;
                    }
                    case ":":
                    {
                        if (!dialogue)
                            narration = true;
                    }
                    case "char":
                    {
                        character = true;
                    }
                    case "~":
                    {
                        overlay = true;
                    }
                    default:
                    {
                        if (convo || option)
                        {
                            text += word;
                        }
                        else if (narration || character || dialogue || overlay)
                        {
                            text += word + " ";
                        }
                        else if (first)
                        {
                            charName = word;
                            dialogue = true;
                        }
                        else if (isAChoice)
                        {
                            if (arrow)
                            {
                                choiceInstruction += word + " ";
                            }
                            else
                            {
                                choiceText += word + " ";
                            }
                        }
                    }
                }

                value = data.line;
                data = getNextWord(value);
                word = data.word;
                first = false;
            }

            if (convo)
            {
                checkChoices();

                if (currentBlock != null)
                {
                    _blocks.push(currentBlock);
                    currentBlock = new CommandBlock();
                }
                
                if (currentBlock == null)
                    currentBlock = new CommandBlock();
                
                currentBlock.id = Command.GLOBAL_ID++;
                currentBlock.title = text;
                text = "";
                convo = false;
            }
            else if (narration)
            {
                checkChoices();
                text = text.substr(0, text.length - 1);
                currentBlock.commands.push(Command.createNarrative(text));
                text = "";
                narration = false;
            }
            else if (character)
            {
                checkChoices();
                text = text.substr(0, text.length - 1);
                _commands.push(Command.createCharacterCommand(text, ""));
                text = "";
                character = false;
            }
            else if (dialogue)
            {
                checkChoices();
                text = text.substr(0, text.length - 1);
                currentBlock.commands.push(Command.createDialogue(charName, text));
                charName = "";
                dialogue = false;
                text = "";
            }
            else if (overlay)
            {
                checkChoices();
                text = text.substr(0, text.length - 1);
                currentBlock.commands.push(Command.createOverlayTitle(text));
                text = "";
                overlay = false;
            }
            else if (isAChoice)
            {
                choiceInstruction = choiceInstruction.substr(0, choiceInstruction.length - 1);
                choiceText = choiceText.substr(0, choiceText.length - 1);
                choices.push(choiceText + ";" + choiceInstruction);
                choiceText = "";
                choiceInstruction = "";
            }
            else if (option)
            {
                if (text == "EXCLUSIVE")
                {
                    currentBlock.isExclusive = true;
                }
            }
        }
    }


    function getNextWord(value:String):{ word:String, line:String }
    {
        var result = "";
        var index = 0;
        for (i in 0...value.length)
        {
            var char = value.charAt(i);
            index++;
            if (char == " ")
                break;
            else
                result += char;
        }

        value = value.substr(index);
        return { word: result, line: value };
    }
    
    function checkChoices()
    {
        if (isAChoice && currentBlock != null)
        {
            currentBlock.commands.push(Command.createChoices(choices));
            isAChoice = false;
            choices = [];
            _blocks.push(currentBlock);
            currentBlock = new CommandBlock();
        }
    }

    function printError(error:String)
    {
        #if js
        Browser.console.error(error);
        #elseif sys
        Sys.stderr().writeString(error);
        #else
        trace(error);
        #end
    }
    
/**
* PUBLIC FUNCTIONS
**/
    
    /**
     * Get all the characters defined in the file as commands.
     */
    public function getCharacters()
    {
        var commands = new Array<String>();
        for (i in 0..._commands.length)
        {
            var cm = _commands[i];
            if (cm.type == CHARACTER)
            {
                commands.push(cm.data[0]);
            }
        }
        return commands;
    }
    
    /**
     * Get a block of commands by the given title. The title of a block is denoted by 'convo'.
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
    * Get a block of commands by the given id.
    * @param id The identifier to look for.
    **/
    public function getBlockById(id:Int)
    {
        for (i in 0..._blocks.length)
        {
            if (_blocks[i].id == id)
                return _blocks[i];
        }
        return null;
    }

    /**
    * Return all the parsed blocks/conversations.
    **/
    public function getBlocks() return _blocks;
    
}