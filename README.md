# StoryDev 2
StoryDev 2 is a parser for StoryScript, a scripting language designed for interactive storytelling. It's written in Haxe which allows for cross-target development, allowing you to use your scripts in any language and on any platform. Haxe targets C++, C#, JavaScript, ActionScript, Flash, Neko, PHP, Java, Python and Lua. With frameworks such as OpenFL and Kha, StoryDev can be used for native desktop applications, web applications, mobile devices, and even the Raspberry Pi.

## Installing StoryDev 2

To install, use the `haxelib git` command:

    haxelib git sd2 https://github.com/storydev/sd2.git

You can also install from haxelib directly:

	haxelib install sd2

## Using StoryDev 2

StoryDev 2 comes in two parts: The Parser (the thing that parses your scripts), and the Implementation (the Graphical User Interface that displays and runs the parsed results).

Implementation is currently limited to HTML5, but you can implement StoryDev 2 into your engine very easily. All that is required is a user interface that is customised to work with StoryDev 2.

To implement, you can use the [technical specification](https://github.com/storydev/sd2/blob/master/StoryScript.md) for exactly how StoryDev parses scripts. Tutorials will become available at a later time.

### A Simple Example

To get started with a simple example, you can use the command:
    
    haxelib run sd2 create "My Simple Example" js

Which will create the folder "My Simple Example" and copy the JavaScript template files along with starting assets into the folder.

Use `cd "My Simple Example"` followed by `haxelib run sd2 build` to build the project. The build command requires `project.json` to exist in the root of the project's folder.

### The project.json structure

If you're creating a custom implementation for StoryDev 2 and you wish to build using the `run sd2 build` command, a `project.json` file is required for the run module to work.

Here is the simple structure it requires:

  1. output - This is the output file or folder (depending on target).
  2. target - This is the target language you want to build to. Follow the [Haxe manual](http://haxe.org/manual/compiler-usage.html) for more information on targets.
  3. convos - This is the folder path containing all conversations with the `*.sdc` file extension. Make sure the extension exists, or the run module won't pick up the file.

## Community

If you would like to join the community, please feel free to visit our [community forums](http://www.storydev.co.uk/community/). Here, we will keep you up-to-date on news and provide you with the latest version of StoryDev 2.

We also encourage you to use the community forums for posting any feedback you have for this project. Please post there for any particular issues you may have that may not directly be related the engine itself, and rather the templates. You will find we have specific categories for scripting, templates and setting up.

You can also contribute your own custom-made templates or share an interactive story you've been working on.

## Contributions

While we encourage pull requests for improving or fixing bugs in StoryDev 2, please be aware that changes to syntax or the way in which the parser works will not be accepted, unless there is a clear and reasonable explanation as to why.

If you want to contribute templates, please submit them to our [forums](http://www.storydev.co.uk/community/) as this is the best way to reach out to other members of the community. This way, you can also get feedback for your template and, if enough people use it, we may ask for your permission to add it officially later at our discretion.