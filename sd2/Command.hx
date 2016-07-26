package sd2;

using sd2.CommandType;

class Command
{

    public static var GLOBAL_ID:Int;
    
    public var id:Int;
    public var type:Int;
    public var data0:String;
    public var data1:String;
    public var data2:String;
    public var data3:String;
    
    public function new()
    {
    }
    
    public static function createCharacterCommand(characterName:String, color:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = CHARACTER;
        command.data0 = characterName;
        command.data1 = color;
        return command;
    }
    
    public static function createBlockTitle(name:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = BLOCK_START;
        command.data0 = name;
        return command;
    }
    
    public static function createNarrative(description:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = NARRATIVE;
        command.data0 = description;
        return command;
    }
    
    public static function createDialogue(character:String, dialogue:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = DIALOGUE;
        command.data0 = character;
        command.data1 = dialogue;
        return command;
    }
    
    public static function createOverlayTitle(title:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = OVERLAY_TITLE;
        command.data0 = title;
        return command;
    }
    
    public static function createCodeLine(code:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = CODE_LINE;
        command.data0 = code;
        return command;
    }
    
    public static function createInternalDialogue(char:String, text:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = INTERNAL_DIALOGUE;
        command.data0 = char;
        command.data1 = text;
        return command;
    }
    
    public static function createNewConvo(title:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = NEW_CONVO;
        command.data0 = title;
        return command;
    }
    
    public static function createChoices(choice1:String, choice2:String, choice3:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = CHOICES;
        command.data0 = choice1;
        command.data1 = choice2;
        command.data2 = choice3;
        return command;
    }
    
}