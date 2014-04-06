DT4 Guide
=========

This document is a guide to writing DT4 template files.
You can write templates with any text editor of your choice,
there is currently no editors that support syntax highlighting
and error checking for DT4.

Text Blocks
-----------

The most simple element of a template is the text block.
It consists of just normal text and is directly copied to the
output. The first leading whitespace in a text block is ignored.

Example:
    This is a text block.
    What is written here will be directly copied to the output,
    
    complete with line breaks and everything.

Control Blocks
--------------

Control blocks are blocks of code to control the output.
You can put any valid dart code in them.
A control block starts with `<#` and ends with `#>`.

When a control structure wraps around a text block,
the text block becomes dependent on that control structure.
For example:
    <# for(int i = 0; i < 10; i++) { #>
    This line is written 10 times.
    <# } #>

Expression Blocks
-----------------

When you want to generate some text from code, you can
use an expression block.
It starts with `<#=` and ends with `#>`.

In the following example, we write 10 lines, each with its line
number:
    <# for(int i = 0; i < 10; i++) { #>
    Line number <#= i + 1 #>
    
    <# } #>
    
The extra new line is necessary because the first new line will
be trimmed off. This example produces the following output:
    Line number 1
    Line number 2
    Line number 3
    etc.
    
Directives
----------

Directives specify metadata for the template, i.e. details on
how to process the template.
A directive has the format `<#@name value#>`.

The `output-name` directive specifies the (file-)name to
write any output to. By default, the output name is empty.
The dt4.dart executable treats the output name as a file name
for the output.
The following example writes 'Hello world!' to the file 'world.txt'
and 'Hello universe!' to 'universe.txt'.
    <# @ output-name   world.txt        #>
    Hello world!
    <#@output-name universe.txt#>
    Hello universe!

The `import` directive specifies a library to import for control blocks.
The following example specifies to import the math library and the yaml package.
    <#@ import dart:math#>
    <# @import package:yaml/yaml.dart#>
    ...
Please note that any referenced packages must already be installed on your machine.

The `param` directive specifieds input parameters to the template.
The following example outputs a list of clients:
    <#@ output-name clients.csv #>
    <#@ param clients #>
    <# var clientList = clients.split(' ');
    for(var c in clientList) { #>
    <#=c#>,<#}#>
(It actually just converts a space seperated list into a comma seperated list.)

Utility Functions
-----------------

The following top-level functions can be used in control blocks:

*`write(obj)` writes `obj` to the output.
*`writeln([obj])` writes `obj` to the output, followed by a line seperator.
*`setOutput(name)` changes the output name ot `name`. This has the same effect as `<#@output-name name#>`.

Behind the scenes
-----------------

The way transformation is done is as follows:
1. The template is split into blocks
2. The blocks are converted to code
3. The code is saved to a temp file
4. A new isolate is spawned from the temp file
5. The code runs in the new isolate and reports the result
6. The temp file is deleted

This means that transformation can currently
only be done on the server.