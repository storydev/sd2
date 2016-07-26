package sd2;

@:enum
abstract CommandType(Int) from Int to Int {
    var CHARACTER:Int           = 0;
    var BLOCK_START:Int         = 1;
    var NARRATIVE:Int           = 2;
    var DIALOGUE:Int            = 3;
    var OVERLAY_TITLE:Int       = 4;
    var CODE_LINE:Int           = 5;
    var INTERNAL_DIALOGUE:Int   = 6;
    var NEW_CONVO:Int           = 7;
    var CHOICES:Int             = 8;
}