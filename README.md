## Requirements

This module is only for the gui-version and not for the terminal version. It is testet on the Linux and Windows environment. Mac should also work.

---

## Installation

- rename the downloaded packagefolder in **`textadept-dev-tools`** and put it into your **`~/.textadept/modules`** directory. If you want to overwrite the folder of a previous version, make sure to save your existing projects before.
- put in your **`~/.textadept/init.lua`** the following line: **`require "textadept-dev-tools"`**

---

## Features

#### Work with projects
- define the directory of projects sources (project-files) with respect to an optional filter
- define customized run-, compile- and build-commands
- define pathes to libraries the project depends on with respect to an optional filter. The library pathes are only used for search purpose

#### Extended functions
There are some extended functions that the user can activate/deactivate from the menu: **`Dev-Tools -> Settings`**. These functions extend the default behaviour of the underlying functions and overwrite/extend their keybindings.

| Function | Keys | Description |
|--|--|--|
| *Find extended* | **`(Ctrl+f ; Cmd+f)`** | If there there is a single selection the selected text will be put into the *find_entry_text *|
| *Select Word extended* | **`(Ctrl+Shift+d ; Cmd+Shift+d)`** | Select word is extended with putting the selected word into the *find_entry_text*. This enables to directly cycle through the occurrences of the text with *find_next* and *find_prev* |
| *Join lines extended* | **`(Ctrl+Shift+j ; \^j)`** | Join selected lines with shrinking all the whitespace in between lines to 1 space |
| *Cut extended* | **`(Ctrl+x ; Cmd+x)`** | If nothing is selected and the user calls cut, then the current line will be cutted |
| *Run extended* | **`(Ctrl+r ; Cmd+r)`** | Before the command is executed the current *view_buffer_state* is stored. If there is a project loaded the project's *run_main_filepath* and *run_commands* will be respected |
| *Compile extended* | **`(Ctrl+Shift+r ; Cmd+Shift+r)`** | Before the command is executed the current *view_buffer_state* is stored. If there is a project loaded the project's *compile_main_filepath* and *compile_commands* will be respected |
| *Build extended* | **`(Ctrl+Shift+b ; Cmd+Shift+b)`** | Before the command is executed the current *view_buffer_state* is stored. If there is a project loaded the project's *build_commands* will be respected |


#### Additional functions

There are additional functions that can be called from the menu or via keybindings. Most of these keybindings are a keychain that can be activated with **`Alt+d`**.

| Function | Keys | Description |
|--|--|--|
| *Open Settings* |**`Alt+d os`** | Opens the settings file for controlling functions behaviour and keybindings |
| *Rename File* | **`Alt+d rf`** | Opens a dialog to rename the filename of the current buffer. On rename the buffer will be closed and directly reopened afterwards |
| *Goto Keyline* | **`Ctrl+g`** | Opens a dialog with the lines in the current buffer that are matching predefined patterns. Patterns are defined in **`keylines.lua`**. There are currently a limited number of languages supported, but additional patterns can be added easily if one knows about the syntax of the language and regular expressions |
| *Goto Origin* |**`Ctrl+Shift+g`** | Every time a *Goto Keyline* or *Goto related Keyline* command is applied a new origin is defined. With *goto_origin* the user can go back to this point |
| *Switch Print Buffers* | **`(Ctrl+Alt+Enter ; Cmd+Alt+Enter)`** | For all Views, if the current Buffer is a Print-Buffer (i.e. Find_in_Files_Buffer, Message_Buffer), then switch to the previous Buffer that wasn't a Print-Buffer |
| *Load Project* | **`Alt+d lp`** | Opens a dialog to choose one of the stored projects. After a project is loaded, it persists (even after restart) until it's unloaded |
| *Unload project* | **`Alt+d up`** | Unloads the current project |
| *New project* | **`Alt+d np`** | Opens a dialog to put in project's name and opens the project config-file afterwards |
| *Configure project* | **`Alt+d cp`** | Configuration of loaded project by opening the project's configuration file |
| *Quick open project* | **`Alt+d qop`** | Quick Open of defined project files |
| *Find in Project* | **`Alt+d fip`** | Finds search text in project files and print results to [Files-Found-Buffer]. All open files are saved before and existing content in [Files-Found-Buffer] is cleared before |
| *Replace in project* | **`Alt+d rip`** | Opens a dialog to input a replace text, then replaces all occurrences of *Find in Project* results. Works only if the current buffer is the [Files-Found-Buffer] and there are *Find in Project* results |
| *Find+Replace in project* | **`Alt+d frip`** | First does *Find in Project* and directly afterwards *Replace in Project* |
| *Find in Libraries* |**`Alt+d fil`** | Find search text in project libraries and print results to [Files-Found-Buffer]. All open files are saved before and existing content in [Files-Found-Buffer] is cleared before |
| *Quick open in Libraries* | **`Alt+d qol`** | Quick Open of defined library files |
| *Close Library-Buffers* |**`Alt+d clb`** | Closes all Buffers which filepath is defined in the project's library pathes |
| *Goto related Keyline* |**`f12`** | Takes the Word under the caret and finds related keylines in defined project files. Optional: if *goto_lib=true*, then search also in the project libraries |

##### Notice:
The keybindings **`Ctrl+g`** and **`Ctrl+shift+g`** for *Goto Keyline* and *Goto Origin* are in conflict with the keybinings for *find_next* and *find_prev*. On Linux/Win there is an alternative for these functions with the keys **`F3`** and **`Shift+F3`**. On Mac the user has to find his own solution.

#### Additional Settings

| Name | Description |
|--|--|
|*prefered_view_idx*| view number where the output of run-, compile- and build-commands, as well as the results of *find_in_project* and *find_in_libraries* is printed out. If set to *nil*, then the current view is used to print |
|*goto_lib*| indicates whether the function *Goto related Keyline* should take the project libraries into account |
|*libs_read_only*| when open a file that is contained in the project libraries, the buffer is set to *read_only=true* if this flag is set to true |
