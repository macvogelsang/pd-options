# Playdate Portable Options

A simple to use and portable options class for the Playdate Lua SDK.

## Features
- Declarative option definition syntax
- List, toggle, and slider option styles
- Automatic saving and loading of user settings
- Dirty read support (any Option:read() can be configured to return `nil` when value hasn't changed)
- Ability to lock some options from being changed given a value of another option

## Installation

1. Copy the `options.lua` file into your project's Source folder.
2. `import 'path/to/options'` in your `main.lua` file
3. Initilize the Options class a global variable. EX: `Opts = Options()`.
4. Done!

