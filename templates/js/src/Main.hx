package;

import js.Lib;
import js.Browser;
import js.html.Element;
import js.html.HTMLDocument;
import js.JQuery in Jq;

import hscript.Parser in HParser;
import hscript.Interp;

import sd2.Parser;
import sd2.Command;
import sd2.CommandBlock;
using sd2.CommandType;

class Main 
{
    
    private static var characters:Array<Command>;
    private static var choices:Element;
    private static var content:Element;
    private static var map:Element;
    private static var p:Parser;
    
    private static var _interp:Interp;
    private static var _parser:HParser;
    private static var _index:Int;
    private static var _commands:CommandBlock;
    private static var _chosenIndices:Array<Int>;
    
    private static var doc:HTMLDocument = Browser.document;
	
	public static function main()
	{
        _chosenIndices = [];
        
        _parser = new HParser();
        _interp = new Interp();
        
        _interp.variables.set("showCharacterInput", showCharacterInput);
        _interp.variables.set("goto", script_Goto);
        
		p = new Parser("start", _interp, _parser);
        
        content = doc.getElementById("narration");
        choices = doc.getElementById("choice");
        map = doc.getElementById("map");
        
        characters = p.getCharacters();
        _index = 0;
        
        choices.innerHTML = "";
        _commands = p.getBlockByTitle("Start");
        next();
	}
    
    private static function getCharacter(name:String)
    {
        for (i in 0...characters.length)
        {
            if (characters[i].data0 == name)
                return characters[i];
        }
        return null;
    }
    
    private static function next()
    {
        if (_index + 1 > _commands.commands.length)
        {
            choices.setAttribute("visibility", "hidden");
        }
        else
        {
            var cmd = _commands.commands[_index++];
            if (cmd.type == NARRATIVE)
            {
                var eval = p.parseText(cmd.data0);
                if (cmd.data0.indexOf("::") > -1)
                {
                    eval = p.parseNarrative(eval);
                }
                
                addNarrative(eval);
                addNextChoice();
            }
            else if (cmd.type == DIALOGUE)
            {
                var eval = p.parseText(cmd.data1);
                if (cmd.data1.indexOf("::") > -1)
                {
                    eval = p.parseNarrative(eval);
                }
                
                addDialogue(getCharacter(cmd.data0), eval);
                addNextChoice();
            }
            else if (cmd.type == OVERLAY_TITLE)
            {
                addOverlayTitle(cmd.data0);
            }
            else if (cmd.type == INTERNAL_DIALOGUE)
            {
                addBasicDialogue(_interp.variables.get(cmd.data0), p.parseText(cmd.data1));
                addNextChoice();
            }
            else if (cmd.type == CODE_LINE)
            {
                p.executeCode(cmd.data0);
                if (p.AutomaticNext)
                    next();
            }
            else if (cmd.type == NEW_CONVO)
            {
                gotoConvo(cmd.data0);
            }
            else if (cmd.type == CHOICES)
            {
                
                
                var array = new Array<String>();
                if (cmd.data0 != "")
                    array.push(cmd.data0);
                if (cmd.data1 != "")
                    array.push(cmd.data1);
                if (cmd.data2 != "")
                    array.push(cmd.data2);
                
                addShowChoices(array);
            }
        }
    }

    private static function addNarrative(value:String)
    {   
        content.insertAdjacentHTML('beforeend', '<p class="new-item">$value</p>');
    }

    private static function addBasicDialogue(char:String, dialogue:String)
    {
        content.insertAdjacentHTML('beforeend', '<p class="new-item">$char<br>$dialogue</p>');
    }
    
    private static function addDialogue(character:Command, dialogue:String)
    {
        content.insertAdjacentHTML('beforeend', '<p class="new-item"><span style="color: #${character.data1}">${character.data0}</span><br>$dialogue</p>');
    }
    
    private static function addNextChoice()
    {
        choices.innerHTML = "";
        var nextLink = doc.createLIElement();
        nextLink.onclick = next;
        nextLink.innerText = "Next";
        choices.appendChild(nextLink);
    }

    private static function addShowChoices(choiceArray:Array<String>)
    {
        choices.innerHTML = "";
        for (i in choiceArray)
        {
            var text = i.substr(0, i.indexOf(','));
            var goto = i.substr(i.indexOf(',') + 1);
            var block = p.getBlockByTitle(goto);
            if (_commands.isExclusive && hasChoiceBeenChosen(block.id))
                continue;
            
            var choiceLink = doc.createLIElement();
            choiceLink.onclick = function()
            {
                if (_commands.isExclusive)
                {
                    _chosenIndices.push(block.id);
                }
                
                gotoConvo(goto, block);
            };
            choiceLink.innerText = text;
            choices.appendChild(choiceLink);
        }
    }
    
    private static function hasChoiceBeenChosen(id:Int)
    {
        for(i in 0..._chosenIndices.length)
        {
            if (_chosenIndices[i] == id)
                return true;
        }
        return false;
    }
    
    private static function script_Goto(title:String, ?block:CommandBlock)
    {
        var commands = block != null ? block : p.getBlockByTitle(title);
        
        if (commands != null)
            _commands = commands;
        else
            return;
        
        if (_commands.clearCurrent)
            clearContent();
        
        _index = 0;
    }
    
    private static function gotoConvo(title:String, ?block:CommandBlock)
    {
        script_Goto(title);
        next();
    }
    
    private static function addOverlayTitle(title:String)
    {
        new Jq("#narration").fadeOut(1200);
        new Jq("#choice").fadeOut(1200, function()
        {
            clearContent();
            
            new Jq("#title-overlay").html('<p>$title</p>');
            new Jq("#title-overlay").fadeIn(3000, function()
            {
                new Jq("#title-overlay").fadeOut(3000, function()
                {
                    next();
                    new Jq("#narration").fadeIn(1000);
                    new Jq("#choice").fadeIn(1000);
                });
            });
        });
    }

    private static function showCharacterInput()
    {
        choices.innerHTML = "";
        var input = doc.createInputElement();
        input.type = "text";
        input.setAttribute("float", "left");
        
        var submit = doc.createButtonElement();
        var confirmText = doc.createTextNode("Confirm");
        submit.appendChild(confirmText);
        
        submit.setAttribute("float", "left");
        submit.onclick = function()
        {
            _interp.variables.set("name", input.value);
            choices.innerHTML = "";
            next();
        };
        
        choices.appendChild(input);
        choices.appendChild(submit);
    }

    private static function clearContent()
    {
        choices.innerHTML = "";
        content.innerHTML = "";
    }
	
}