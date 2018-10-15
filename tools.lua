local keylines = require "textadept-dev-tools.keylines"
local str = require "textadept-dev-tools.tools_string"
local nav = require "textadept-dev-tools.navigation"


local M = {}

-- Helper-Function:
local get_first_non_empty_line=function(buffer)
    local first_line_number=0
    local line=str.trim(buffer.get_line(first_line_number))
    while line=="" do
        first_line_number=first_line_number+1
        line=str.trim(buffer.get_line(first_line_number))
    end
    return line
end
M.get_first_non_empty_line=get_first_non_empty_line

-- Helper-Function:
local get_last_non_empty_line=function(buffer)
    local last_line_number=buffer.line_count
    local line=str.trim(buffer.get_line(last_line_number))
    while line=="" do
        last_line_number=last_line_number-1
        line=str.trim(buffer.get_line(last_line_number))
    end
    return line
end
M.get_last_non_empty_line=get_last_non_empty_line

-- Helper-Function:
-- finds lines in buffer's text which match one of the regex_patterns. returns table with sorted lines_num and table with associated lines_text.
local find_lines_in_buffer=function(buffer, regex_patterns)
    local lines_text, lines_num = {}, {}
    -- return if binary-text:
    local binary=buffer:text_range(0, 65536):find('\0')
    if binary then return lines_text, lines_num end
    -- Loop over regex_patterns and over buffers text:
    local search_flags_before=buffer.search_flags
    buffer.search_flags=buffer.FIND_REGEXP
    for _, regex_pattern in ipairs(regex_patterns) do
        buffer:target_whole_document()
        while buffer:search_in_target(regex_pattern) > -1 do
            local line_num = buffer:line_from_position(buffer.target_start)
            local line_text = buffer:get_line(line_num)
            -- jump over if line is already there for other pattern:
            if lines_text[line_num]==nil then
                table.insert(lines_num, line_num)
                --remove carriage-return and newline-symbols:
                lines_text[line_num]=string.gsub(string.gsub(line_text,'\r',''),'\n','')
            end
            buffer:set_target_range(buffer.target_end, buffer.length)
        end
    end
    buffer.search_flags=search_flags_before
    table.sort(lines_num)
    return lines_num, lines_text
end
M.find_lines_in_buffer=find_lines_in_buffer

-- Helper-Function:
-- fits current_pos into-view, s.t. it appears 10 lines from top of view-window if possible:
local fit_into_view=function()
    -- use policy to keep cursor after scrolling away from view-border:
    local policy_store=buffer.y_caret_policy
    buffer:set_y_caret_policy(13,10)
    buffer:scroll_to_end()
    buffer:goto_pos(buffer.current_pos)
    buffer.y_caret_policy=policy_store
end
M.fit_into_view=fit_into_view

-- Extension of find: If there there is a single selection the selected text will be put into the find_entry_field
local find_extended=function()
    if not buffer.selection_empty and buffer.selections == 1 then
        ui.find.find_entry_text=buffer:get_sel_text()
    end
    textadept.menu.menubar[_L['_Search']][_L['_Find']][2]()
end
M.find_extended=find_extended

--Select word is extended with putting the selected word into the find_entry_text. This enables to directly cycle through the occurrences of the text with find_next and find_previous
local select_word_extended=function()
    textadept.editing.select_word()
    -- puts selected word in find_entry_text s.t. search-next works for selected word:
    if buffer.selections == 1 then
        ui.find.in_files=false
        ui.find.find_entry_text=buffer:get_sel_text()
    end
end
M.select_word_extended=select_word_extended

--Join selected lines with shrinking all the whitespace in between lines to 1 space
local join_lines_extended=function()
    textadept.editing.join_lines()
    local line_text=buffer:get_line(buffer:line_from_position(buffer.current_pos))
    buffer:vc_home()
    buffer:line_end_extend()
    buffer:replace_sel(str.trim(str.shrink_whitespace(line_text)))
end
M.join_lines_extended=join_lines_extended


-- If nothing is selected and the user calls cut, then the current line will be cutted
local cut_extended=function()
    if buffer.selection_empty then
        buffer:line_copy()
        buffer:line_delete()
    else
        buffer:cut()
    end
end
M.cut_extended=cut_extended

-- Goto Keyline opens a Dialog with Lines in the current-buffer that matches predefined patterns. Patterns are defined in 'keylines.lua':
local goto_keyline=function()
    -- get file-extension and its keylines:
    local _,_,extension=str.split_path(buffer.filename)
    local name=nil
    local keyline_patterns=keylines.get_patterns_for_attribute(name)
    if keyline_patterns[extension]==nil then return end

    -- searching for lines that matches keyline-patterns:
    local lines_num, lines_text =
        find_lines_in_buffer(buffer, keyline_patterns[extension])

    --set up line_items for filteredlist-dialog:
    local line_items={}
    for _,line_num in ipairs(lines_num) do
        table.insert(line_items, line_num+1) --add 1 because buffer-lines start at 1 instead of 0
        table.insert(line_items, lines_text[line_num])
    end

    -- show dialog and goto line in case of selection:
    local button,i=ui.dialogs.filteredlist{
        title = 'Goto Keyline',
        columns = {'Line', 'Text'},
        items = line_items,
        search_column=2}
    if button==1 and i then
        -- determine origin as current buffer together with current pos:
        local origin={buffer = buffer, pos = buffer.current_pos}
        -- jump to new line:
        local line_num=line_items[2*i-1]
        buffer:goto_line(line_num)
        fit_into_view()
        return origin
    end
end
M.goto_keyline=goto_keyline

-- Jumps in current_view to a origin which is a table with keys 'buffer' and 'pos'
local goto_origin=function(origin)
    view:goto_buffer(origin.buffer)
    buffer:goto_pos(origin.pos)
    fit_into_view()
end
M.goto_origin=goto_origin

-- Opens a dialog to rename the filename of the current buffer. On rename the buffer will be closed and directly reopened afterwards
local rename_file=function()
    local filename_current=buffer.filename
    local return_code,filename_new=ui.dialogs.standard_inputbox{
        title='Rename File',
        informative_text=filename_current,
        text=filename_current}
    if return_code==1 then
        io.save_file()
        local rename_result=os.rename(filename_current, filename_new)
        if rename_result==true then
            io.close_buffer()
            io.open_file(filename_new)
        else
            ui.dialogs.msgbox{title="Rename-Error", text="Invalid Filepath"}
        end
    end
end
M.rename_file=rename_file

-- Opens the settings-file for controlling functions-behaviour and keybindings
local open_settings=function()
    local settings_file=_USERHOME..'/modules/textadept-dev-tools/settings.lua'
    io.open_file(settings_file)
end
M.open_settings=open_settings

return M
