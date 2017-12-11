# StoryDev 2
StoryDev 2 is a parser for StoryScript, a scripting language designed for interactive storytelling. It's written in Haxe which allows for cross-target development, allowing you to use your scripts in any language and on any platform. Haxe targets C++, C#, JavaScript, ActionScript, Flash, Neko, PHP, Java, Python and Lua. With frameworks such as OpenFL and Kha, StoryDev can be used for native desktop applications, web applications, mobile devices, and even the Raspberry Pi.

The purpose of StoryDev is to abstract storytelling from logic. Unlike most interactive story-telling scripting engines, we encourage writer's to do what they do best without needing to worry about logic. Scripting is optional, and while the feature exists it is generally recommended to implement hard-coded scripting with your implementation as that would perform faster than scripts using hscript (which this engine would otherwise use by default).

## Installing StoryDev 2

To install, use the `haxelib git` command:

    haxelib git sd2 https://github.com/storydev/sd2.git

You can also install from haxelib directly:

	haxelib install sd2

StoryDev 2 is also dependent on `hscript`. You can get this [here](https://github.com/HaxeFoundation/hscript).

## Using StoryDev 2

StoryDev 2 comes in two parts: The Parser (the thing that parses your scripts), and the Implementation (the Graphical User Interface that displays and runs the parsed results).

The parser is what exists, whereas the implementation is up to you to decide. This will give you freedom over how you wish to display conversations, dialogue and choices.