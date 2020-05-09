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

#if (sys || hxnodejs)
import sys.io.File;
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
    private var blocksAdded:Int = 0;
    
    public function new()
    {
        Command.GLOBAL_ID = 0;
        
        _blocks = [];
        _commands = [];
        addedResources = [];
    }

    /**
    * If for some reason you want to clear all the parsed content,
    * you can do so by calling this function.
    **/
    public function clear()
    {
        _blocks = [];
        _commands = [];
    }
    
    /**
    * Parse a file into `CommandBlock`s. Returns an integer value that indicates
    * the number of `CommandBlock`s generated. This can be useful if you need to
    * manage the layout of your conversations according to your application.
    **/
    public function parseFile(file:String, filesystem:Bool = false):Int
    {
        var content = "";

        if (filesystem)
        {
            #if (sys || hxnodejs)
            content = File.getContent(file);
            #end
        }
        else
        {
            #if twinspire
            var _index = Application.resources.loadMisc(file);
            var _file:Blob = Application.resources.misc[_index];

            content = _file.readUtf8String();
            #elseif kha
            var _file:Blob = Reflect.field(Assets.fonts, file);

            content = _file.readUtf8String();
            #else
            content = Resource.getString(file);

            #end
        }

        var lines = content.split("\n");
        currentBlock = null;
        isAChoice = false;
        isDialogueBlock = false;
        blocksAdded = 0;

        // setup the local variables
        // don't need tokenisation because we are simple.
        choices = [];
        var convo = false;
        var character = false;
        var overlay = false;
        var text = "";
        var narration = false;
        var dialogue = false;
        var isCode = false;
        var charName = "";
        var charColor = "";
        var choiceText = "";
        var choiceInstruction = "";
        var optionText = "";
        var option = false;
        var codeText = "";

        for (i in 0...lines.length)
        {
            var line:String = lines[i];

            if (line == "" || line == "\r")
                continue;
            
            if (line.endsWith("\r"))
                line = line.substr(0, line.length - 1);

            // set up the value and get the entire line
            var value = line;
            // get the next word, which returns to us the word itself, and the rest of the line.
            var data = getNextWord(value);
            var word = data.word;
            // this is the first word in the line
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
                        if (!isCode)
                            option = true;
                    }
                    case "convo", "#":
                    {
                        convo = true;
                    }
                    case ":":
                    {
                        if (!isCode)
                        {
                            if (!dialogue)
                                narration = true;
                            else
                            {
                                charName = text;
                                text = "";
                            }
                        }
                    }
                    case "char":
                    {
                        if (first)
                            character = true;
                        else if (dialogue || narration || overlay)
                            text += word + " ";
                    }
                    case "~":
                    {
                        if (first)
                            overlay = true;
                    }
                    case "!":
                    {
                        isCode = true;
                    }
                    default:
                    {
                        if (option)
                        {
                            text += word;
                        }
                        else if (narration || character || dialogue || overlay || convo || isCode)
                        {
                            if (character && word.startsWith("#"))
                                charColor = word;
                            else if (isCode)
                            {
                                codeText += value;
                                break;
                            }
                            else 
                            {
                                text += word + " ";
                            }
                        }
                        else if (first)
                        {
                            text = word + " ";
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

                // set the value to the rest of the line and get the next word.
                value = data.line;
                data = getNextWord(value);
                word = data.word;
                first = false;
            }

            // check what happened when we parsed the line and create
            // commands/blocks accordingly.
            if (convo)
            {
                checkChoices();

                if (currentBlock != null)
                {
                    _blocks.push(currentBlock);
                    blocksAdded++;
                    currentBlock = new CommandBlock();
                }
                
                if (currentBlock == null)
                    currentBlock = new CommandBlock();
                
                currentBlock.id = Command.GLOBAL_ID++;
                currentBlock.title = text.substr(0, text.length - 1);
                currentBlock.resourceOrigin = file;
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
                _commands.push(Command.createCharacterCommand(text, charColor));
                text = "";
                character = false;
            }
            else if (dialogue)
            {
                checkChoices();
                text = text.substr(0, text.length - 1);
                charName = charName.substr(0, charName.length - 1);
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
                if (!arrow)
                {
                    postError('Line $i: There must be an `->` arrow that indicates where to go in a choice.');
                    return -1;
                }

                if (isCode)
                    choiceInstruction = codeText;
                
                if (!isCode)
                    choiceInstruction = choiceInstruction.substr(0, choiceInstruction.length - 1);
                
                choiceText = choiceText.substr(0, choiceText.length - 1);
                choices.push(choiceText + "|" + choiceInstruction);
                choiceText = "";
                choiceInstruction = "";
                codeText = "";
            }
            else if (isCode)
            {
                currentBlock.commands.push(Command.createCodeLine(codeText));
                codeText = "";
                isCode = false;
            }
            else if (option)
            {
                if (text == "EXCLUSIVE")
                {
                    currentBlock.isExclusive = true;
                }

                text = "";
                option = false;
            }
            else
            {
                postError('Invalid syntax at line $i. What we\'re you trying to do?');
                return -1;
            }

            if (i == lines.length - 1)
            {
                if (currentBlock != null)
                {
                    checkChoices();
                    _blocks.push(currentBlock);
                    blocksAdded++;
                }
            }
        }

        return blocksAdded;
    }

    public function generateContent(block:CommandBlock)
    {
        var content = "";
        if (block.title == null) return "";

        content = "convo " + block.title + "\n";
        if (block.isExclusive)
            content += "= EXCLUSIVE\n";

        for (i in 0...block.commands.length)
        {
            var command = block.commands[i];
            switch (command.type)
            {
                case CommandType.NARRATIVE:
                {
                    content += ": " + command.data[0] + "\n";
                }
                case CommandType.DIALOGUE:
                {
                    content += command.data[0] + " : " + command.data[1] + "\n";
                }
                case CommandType.OVERLAY_TITLE:
                {
                    content += "~ " + command.data[0] + "\n";
                }
                case CommandType.CODE_LINE:
                {
                    content += "! " + command.data[0] + "\n";
                }
                case CommandType.CHOICES:
                {
                    for (data in command.data)
                    {
                        var index = data.indexOf(";");
                        var choiceText = data.substr(0, index);
                        var choiceInstruction = data.substr(index + 1);
                        content += "> " + choiceText + " -> " + choiceInstruction + "\n";
                    }
                }
            }
        }

        return content;
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
        var result = false;
        if (isAChoice && currentBlock != null)
        {
            currentBlock.commands.push(Command.createChoices(choices));
            isAChoice = false;
            choices = [];

            result = true;
        }

        return result;
    }

    function postError(error:String)
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