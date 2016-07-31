**Please note that these specifications are incomplete.**

# StoryScript Specifications

StoryScript is the language used to write interactive stories with StoryDev 2. It is specifically designed for storytelling, and these specifications were written to provide the detailed, technical information on how the language is parsed.

Please be aware that any changes to the parser may affect the specification, and vice versa. As mentioned in the README, unless it's a bug fix, you may not contribute changes to the parser.

# Introduction
Every file is parsed line-by-line, not character-by-character. And each line is considered a `Command`. Each Command tells the parser what it is that it's looking at, and places it globally within the scope of the parser. The parser is split up between two scopes: Command Blocks (or conversations), and local Commands. Command Blocks are quite simply blocks of commands that contain within it the flow of a single conversation. Locally scoped commands are those captured outside of conversations. These are often in the form of character definitions.

If the end of the current file is reached, the current block is added to the command blocks.

## Character Definitions
Syntax: `% "<char_name>" #<colour_value>`

Character definitions define the names of characters, followed by their respective colour value. Their Command is of type `CHARACTER` and their data are as follows:

  1. `data0` - `<char_name>` - String value
  2. `data1` - `<colour_value>` - Hexadecimal in String value. Use `Std.int` to convert to integer if required.

## Conversation Definitions
Syntax: `$ "<convo_name>" (<extra_data>..)`

Conversation definitions defines a new Command Block with the given name. You can also add extra data, in the form of string values separated by commas. This extra data is stored into `extraData` of the newly defined Command Block. This may be useful if you want to associate the conversation with certain resources within your video game. Their command is of type `BLOCK_START` and their data are as follows:

  1. `data0` - `convo_name` - String value
  2. `extraData` - `extra_data` - Optional. Is a list of strings.

## Narrative
Syntax: `: <text>` or `<char_name> : <text>`

Narrative is either plain text that describes an action or scene in the current context, or a character is saying something. If the first syntax, the type will be `NARRATIVE` with the following data:

  1. `data0` - `<text>` - The text to display.

Otherwise, if it's the latter syntax, the type will be `DIALOGUE` and with the following data:

  1. `data0` - `<char_name>` - The name of the character. You should get the characters using `parser.getCharacters` and iterate through the array until you find the character command with the matching name. That way, you can also use `data1` of that command to highlight the character name in its respective colour.
  2. `data1` - `<text>` - The text to display.

If narrative contains a dollar sign, it is likely it is referencing a variable. You should use `parser.parseText` on either `data0` or `data1` as a convenience function to parse this text and return the values for the referenced variables.

## Script
Syntax: `! <script>`

This would execute a script. The script code is stored inside `data0`. You should use `parser.executeCode` to execute this script when it becomes available. You should also check `parser.AutomaticNext` to determine if you should automatically go to the next command. These are of type `CODE_LINE`.

## Overlays
Syntax: `~ <text>`

These are 3 second fade delays (in default templates) which displays larger overlay text to emphasise something. They are of type `OVERLAY_TITLE` and contains the following data:
  
  1. `data0` - `<text>` - The text to display.

## Conversation Options
Syntax: `= <option>`

Conversation options are data stored inside the command block itself as individual variables. There are two options currently available:

  1. `EXCLUSIVE` - This, as it is implemented in the HTML5 template, only allows options within choices to appear once in the current conversation.
  2. `NOCLEAR` - This, as it is implemented in the HTML5 template, prevents the previous conversation from clearing, creating the illusion that you are still in the same conversation.

These options are stored as boolean values inside of the current block as follows:

  1. `isExclusive` - `true` if the choices within the block are exclusive and only appear once. This needs to be implemented yourself.
  2. `clearCurrent` - `true` if the current conversation (before this block) is cleared from the display as if moving to another conversation.

## Internal Dialogue
Syntax: `__<var_name> : <text>`

This is similar to dialogue, only the `__` is reserved and is identified as if accessing a variable. This is done internally by the parser, but the actual command type is `INTERNAL_DIALOGUE` instead.

## Choices
Syntax: `> <text> -> "<convo_name>"`

These are first parsed by the parser as an array to determine if the number of choices exceeds a length of three. If this is the case, this becomes a parser error. Otherwise, it then stores these choices and joins the text and convo_name with a comma, like so:

    "Choice Text to Display,Name of Convo"

Each choice is data from data0 to data2 inside a command block of type `CHOICES`. You will need to split these apart using `string.split(',')` to get the display text and choice name respectively. You can then use `parser.getBlockByTitle` to get the command block for the respective conversation to go to.

## Go to Conversation definition
Syntax: `:: "<convo_name>"`

This is the conversation goto definition that allows the ability to "goto" another conversation. It has the type of `NEW_CONVO` and stores the following data:

  1. `data0` - `<convo_name>` - The name of the conversation to go to.

