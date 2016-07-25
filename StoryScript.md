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
