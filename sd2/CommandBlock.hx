package sd2;

class CommandBlock
{

    public var id:Int;
    public var title:String;
    public var isExclusive:Bool;
    public var clearCurrent:Bool;
    public var commands:Array<Command>;
    public var extraData:Array<String>;
    
    public function new()
    {
        commands = [];
        extraData = [];
        clearCurrent = true;
        isExclusive = false;
        id = 0;
    }
    
}