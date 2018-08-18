# StoryDev 2
StoryDev 2 is a parser for StoryScript, a scripting language designed for interactive storytelling. It's written in Haxe which allows for cross-target development, allowing you to use your scripts in any language and on any platform. Haxe targets C++, C#, JavaScript, ActionScript, Flash, Neko, PHP, Java, Python and Lua. With frameworks such as OpenFL and Kha, StoryDev can be used for native desktop applications, web applications, mobile devices, and even the Raspberry Pi.

The purpose of StoryDev is to abstract storytelling from logic. Unlike most interactive story-telling scripting engines, we encourage writer's to do what they do best without needing to worry about logic.

## Installing StoryDev 2

To install, use the `haxelib git` command:

    haxelib git sd2 https://github.com/storydev/sd2.git

You can alternatively use the `haxelib dev` command if you clone with git directly.

## Using StoryDev 2

StoryDev 2 comes in two parts: The Parser (the thing that parses your scripts), and the Implementation (the Graphical User Interface that displays and runs the parsed results).

The parser is what exists, whereas the implementation is up to you to decide. This will give you freedom over how you wish to display conversations, dialogue and choices.

### A Simple Script

The language is very simple to learn and use. Take a look at the following example:

```
convo Start
: Welcome to your first interactive story!
Caroline : Hi!
Saniyah : Carol, don't budge.
Caroline : I'm just being nice.
> Respond Nicely -> Respond Nicely
> Respond Harshly -> Respond Harshly
```

Let's break this down into each line:

 1. The `convo` keyword indicates the start of a dialogue block or conversation. Each `convo` is parsed into the parser as a `CommandBlock` and the title is passed in.
 2. Anything preceding `:` is either narrative or dialogue. If the left-side of the colon is *not* empty, this indicates dialogue with the given character name. Character's can be defined with the `char` keyword. More on this later.
 3. Lines with `>` is typically used at the end of the conversation, which indicate choices to be made. Choices can indeed be offered in the middle of a conversation and the parser will not prompt an error. They have the syntax `> [Display Text] -> [Conversation to go to]`.

### Implementation Detail

To implement the above example in a very simple command line interface, we can use the following code:

```haxe
package;

import sd2.Parser;
import sd2.CommandType;

class Main
{

  static var parser:Parser;

  public static function main()
  {
    parser = new Parser();
    // Assuming the above example is used in this file (relative to the program's directory)
    // parse it's contents. We use `true` in the second parameter to indicate we want to use
    // the native file system. If the target doesn't support it, it won't get the file and
    // won't parse. For JavaScript, you can include hxnodejs in your project to support this
    // functionality, but you will need NodeJS installed.
    parser.parseFile("test.sdc", true);
    // Once the file is parsed, we can get the first block if there is one.
    var block = parser.getBlocks()[0];
    if (block == null)
    {
      trace("For some reason, the first block could not be found.");
      return;
    }
    
    for (command in block.commands)
    {
      switch (command.type)
      {
        case CommandType.NARRATIVE:
	{
	  trace(": " + command.data[0]);
	}
	case CommandType.DIALOGUE:
	{
	  trace(command.data[0] + " : " + command.data[1]);
	}
	case CommandType.CHOICES:
	{
	  for (choice in command.data)
	  {
	    // each choice is text with the `;` separating the display text
	    // from the conversation to go to.
	    var display = choice.substr(0, choice.indexOf(";"));
	    var goto = choice.substr(choice.indexOf(";") + 1);
	    trace("> " + display + " -> " + goto);
	  }
	}
      }
    }
  }

}

```

There are other options available. For a full list, see below.

The parser will parse files character by character without regular expressions for maximum performance.

## Syntax Options

`convo` or `#` defines a conversation or dialogue block. Syntax: `convo Start`

`char` defines a character. This is a convenience method which you can use to get colour data if necessary. Syntax: `char Saniyah #00665d`. Colours are optional.

`:` indicates either narrative or dialogue. If a character name is given to the left of the colon, it is parsed as type `DIALOGUE` than `NARRATIVE`. Syntax: `[Character] : This is some dialogue.`

`~` indicates overlay. Overlay is perhaps more often used outside of any dialogue, such as in subtitles in a cutscene. Syntax: `~ This is some overlay.`

`>` indicates choice. This is typically used at the end of conversations, but can be used anywhere. Syntax: `> Display Text -> Go To`

`=` indicates option. This is only really used for the `EXCLUSIVE` option, such as in `= EXCLUSIVE` which marks a block's member variable `isExclusive` true. This can be used for choice hubs, where choices can be hidden once activated. Currently, the parser does not do anything else with this option value.
