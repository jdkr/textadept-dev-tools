local tools = require "textadept-dev-tools.tools"
local keylines = require "textadept-dev-tools.keylines"
local str = require "textadept-dev-tools.tools_string"
local nav = require "textadept-dev-tools.navigation"

-- internal helper function:
local _get_word_under_caret=function()
    local word_start=buffer:word_start_position(buffer.current_pos, true)
    local word_end=buffer:word_end_position(buffer.current_pos, true)
    return buffer:text_range(word_start, word_end)
end

-- internal helper function for getting find-text in some found-buffer:
local _get_find_text=function(buffer)
    assert(nav.is_files_found_buffer(buffer))
    local first_non_empty_line=tools.get_first_non_empty_line(buffer)
    local first_non_empty_line_splitted=str.split(first_non_empty_line, ":")
    local find_text=str.trim(first_non_empty_line_splitted[2])
    return find_text
end

local M={}

-- local constants:
local PROJECTS_DIR=_USERHOME..'/modules/textadept-dev-tools/projects/'
M.PROJECTS_DIR=PROJECTS_DIR
local CURRENT_PROJECT_FILEPATH=PROJECTS_DIR..'current_project'
M.CURRENT_PROJECT_FILEPATH=CURRENT_PROJECT_FILEPATH
local FOUND_PROJECT_IDENTIFIER='FOUND_IN_PROJECT'
local FOUND_LIBS_IDENTIFIER='FOUND_IN_LIBS'


-- Helper-function
local get_current_project=function()
    local file = io.open(CURRENT_PROJECT_FILEPATH, 'r')
    if file==nil then
        return ''
    else
        local project_filename=str.trim(file:read() or '')
        return project_filename
    end
end
M.get_current_project=get_current_project

-- Opens a dialog with to select from the stored projects. After a project is loaded, it persists (even restarts) until it's unloaded. Therefore the choosen project_filename is stored in a file and a reset() is done:
local load_project=function()
    --show List of Project-Files to select from:
    local file=io.open(CURRENT_PROJECT_FILEPATH,'w')
    local return_value=ui.dialogs.fileselect{
        title = 'Load Project',
        with_directory = PROJECTS_DIR,
        with_extension = {'lua'},
        select_multiple = false,
        items = project_files}
    if return_value~=nil then
        local project_filepath=return_value
        local _,project_filename,_=str.split_path(project_filepath)
        file:write(project_filename)
        file:close()
        reset()
        --opens project's filepath to see project-parameter:
        io.open_file(project_filepath)
end end
M.load_project=load_project

-- Unloads the current project by deleting the file with the project's name and doing a reset.
local unload_project=function()
    local file=io.open(CURRENT_PROJECT_FILEPATH,'w')
    file:write('')
    file:close()
    reset()
    ui.dialogs.msgbox{title="Info", text='Project unloaded'}
end
M.unload_project=unload_project

-- Opens a dialog to put in project's name and opens the project config-file afterwards
local new_project=function()
    local return_code,new_project_name=ui.dialogs.standard_inputbox{title='Project name'}
    if return_code~=1 then return end
    -- get template text and paste it in new buffer
    local project_template_file=PROJECTS_DIR..'template'
    local file=io.open(project_template_file)
    local template_text=file:read('*all')
    io.open_file(PROJECTS_DIR..new_project_name..'.lua')
    buffer:set_text(template_text)
end
M.new_project=new_project

--Configuration of loaded project by opening the projects configuration file
local configure_project=function()
    local file = io.open(CURRENT_PROJECT_FILEPATH, 'r')
    local project_filename=str.trim(file:read())
    local project_filepath=PROJECTS_DIR..project_filename
    io.open_file(project_filepath)
end
M.configure_project=configure_project


-- Run project with respect to the project's run_main_filepath and run_commands
local run_project=function(project)
    io.save_all_files()
    textadept.run.run(project.run_main_filepath)
end
M.run_project=run_project

-- Compile project with respect to the project's compile_main_filepath and compile_commands
local compile_project=function(project)
    io.save_all_files()
    textadept.run.compile(project.compile_main_filepath)
end
M.compile_project=compile_project

-- Build project with respect to the project's build_commands
local build_project=function(project)
    io.save_all_files()
    textadept.run.build(project.dir)
end
M.build_project=build_project

-- Finds search text in project files and print results in Files-Found-Buffer. All open files are saved before and existing content in Files-Found-Buffer is cleared before:
-- TODO: For better performance it would be nice to have some kind of function 'find_pattern_in_text'. This function should accept any Regex-pattern and could be used for find_in_project, find_in_libs, goto_keyline and goto_related_keyline. Also it should be independent of a buffer. Currently used find_in_files use a temporary buffer that shows up every time the time-check is done.
-- TODO: It would be nice if one could set the buffers tab_label persistently, or have some other kind of labeling a buffer. Currently in find_in_project and find_in_libs there are identifier used that are printed as a footer, but they can be edited by the user.
local find_in_project=function(project, search_text)
    ui.find.find_entry_text=search_text
    io.save_all_files() -- save all files, because find_in_files only searches on disc

    -- Goto ff-buffer and clear all content:
    ui._print(_L['[Files Found Buffer]'], "")
    assert(buffer._type==_L['[Files Found Buffer]'])
    buffer:clear_all()

    -- Find in specified directories and filters (Results were printed to ff-buffer):
    ui.find.match_case=true
    ui.find.find_in_files(project.dir, project.filter)

    -- print footer to tag found results
    ui._print(_L['[Files Found Buffer]'], FOUND_PROJECT_IDENTIFIER)
end
M.find_in_project=find_in_project

-- Opens a dialog to input a replace text, then replaces all occurrences of 'Find in Project' results. Works only if inside Files-Found-Buffer and there are 'Find in Project' results
local replace_in_project=function()
    if not (nav.is_files_found_buffer(buffer) and
            tools.get_last_non_empty_line(buffer)==FOUND_PROJECT_IDENTIFIER) then
        ui.dialogs.msgbox{title="Info",
            text='Nothing to replace, do first "Find in Project" and go to "[Files Found Buffer]"'}
        return
    end

    -- find_text from found_in_project buffer
    find_text=_get_find_text(buffer)

    -- Input of replace-text:
    local return_code,replace_text=ui.dialogs.standard_inputbox{
        title='Replace in Project',
        informative_text="Found text in project:\n"..find_text,
        text=''}
    if return_code~=1 then return end

    -- update find-replace-pane:
    ui.find.find_entry_text=find_text
    ui.find.replace_entry_text=replace_text

    -- do replacements:
    for i = 0,buffer.line_count do
        -- jump to the buffer with the next find-result.
        ui.find.goto_file_found(nil, true)
        -- deselect all found entries, because following replace_all() only works correct if there are no selections:
        buffer.set_empty_selection(buffer, 0)
        ui.find.replace_all()
    end
end
M.replace_in_project=replace_in_project

-- First does 'Find in Project' and directly afterwards 'Replace in Project':
local find_replace_in_project=function(project)
    find_in_project(project)
    replace_in_project()
end
M.find_replace_in_project=find_replace_in_project

-- gets the text to perform a search via dialog-input:
local get_search_text=function(title)
    local input_text=''
    if not buffer.selection_empty and buffer.selections==1 then
        input_text=buffer:get_sel_text()
    end

    local return_code,search_text=ui.dialogs.standard_inputbox{
        title=title,
        informative_text='Text to find with MatchCase',
        text=input_text}
    if return_code==1 then
        return search_text
    else
        return nil
    end
end
M.get_search_text=get_search_text

-- Find search text in project libraries and print results in Files-Found-Buffer. All open files are saved before and existing content in Files-Found-Buffer is cleared before:
local find_in_libs=function(project, search_text)
    ui.find.find_entry_text=search_text
    io.save_all_files() -- save all files, because find_in_files only searches on disc

    -- Goto ff-buffer and clear all content:
    ui._print(_L['[Files Found Buffer]'], "")
    assert(buffer._type==_L['[Files Found Buffer]'])
    buffer:clear_all()

    -- Find in specified directories and filters (Results were printed to ff-buffer):
    ui.find.match_case=true
    for _,lib in ipairs(project.libraries) do ui.find.find_in_files(lib.dir, lib.filter) end

    -- print footer to tag found results
    ui._print(_L['[Files Found Buffer]'], FOUND_LIBS_IDENTIFIER)
end
M.find_in_libs=find_in_libs

-- Closes all Buffers which filepath is defined in the project's library-pathes
local close_lib_buffers=function(lib_filepaths)
    for _,buff in ipairs(_BUFFERS) do
        if lib_filepaths[buff.filename]~= nil then
            view:goto_buffer(buff)
            io.close_buffer()
        end
    end
end
M.close_lib_buffers=close_lib_buffers


-- getting all lib-filepaths
local get_lib_filepaths=function(project)
    local lib_filepaths={}
    if project.libraries==nil then return lib_filepaths end
    for _,lib in ipairs(project.libraries) do
        if lib.dir=='' then goto next_lib end
        lfs.dir_foreach(
            lib.dir,
            function(filepath) lib_filepaths[filepath]=true end,
            lib.filter)
        ::next_lib::
    end
    return lib_filepaths
end
M.get_lib_filepaths=get_lib_filepaths


-- checks if runtime is ok for the user, returns boolean and in case of a dialog the test_time (time is given in seconds)
local is_runtime_ok=function(time_0, time_intervall)
    if os.time()-time_0>time_intervall then
        local return_code=ui.dialogs.yesno_msgbox{
            title='Question', text='Still running - continue?'}
        if return_code~=1 then return false,nil else return true,os.time() end
    else
        return true,nil
    end
end

-- Takes the Word under the caret and finds related keylines in defined project files. Optional: if goto_lib=true, then search also in the project-libraries:
local goto_related_keyline=function(project, goto_lib)
    -- get keyline-pattern table for word under caret:
    local name=_get_word_under_caret()
    local keyline_patterns=keylines.get_patterns_for_attribute(name)
    -- get filepaths for project with respect to filter:
    local filepaths={}
    lfs.dir_foreach(
        project.dir,
        function(filepath) table.insert(filepaths, filepath) end,
        project.filter)
    -- if libs should be considered, then add this paths:
    if goto_lib==true then
        for _,lib in ipairs(project.libraries) do
            lfs.dir_foreach(
                lib.dir,
                function(path) table.insert(filepaths, path) end,
                lib.filter)
        end
    end
    -- get filepaths that are opened:
    local filepaths_open={}
    for i=1,#_BUFFERS do
        local filepath=_BUFFERS[i].filename
        if filepath~=nil then -- ignore special buffers
            filepaths_open[_BUFFERS[i].filename]=_BUFFERS[i]
        end
    end

    -- do the search (get related Keylines either from open_buffers or from file (with help of temp_buffer):
    local time_0=os.time()
    local related_lines = {}
    local temp_buffer = buffer.new() --temporary buffer
    local lines_num, lines_text = nil, nil
    for _,filepath in ipairs(filepaths) do
        local _,filename,extension=str.split_path(filepath)
        if keyline_patterns[extension]==nil then goto next_filepath end
        if filepaths_open[filepath] then
            lines_num,lines_text =
                tools.find_lines_in_buffer(filepaths_open[filepath],keyline_patterns[extension])
        else
            -- in style of find_in_files:
            temp_buffer:clear_all()
            temp_buffer:empty_undo_buffer()
            local f = io.open(filepath, 'rb')
            while f:read(0) do temp_buffer:append_text(f:read(1048576)) end
            f:close()
            lines_num,lines_text =
                tools.find_lines_in_buffer(temp_buffer,keyline_patterns[extension])
        end
        -- insert into related_lines:
        for _,line_num in ipairs(lines_num) do
            related_lines[{filepath,line_num}]={filename, lines_text[line_num]}
        end
        -- timecheck:
        local continue,test_time=is_runtime_ok(time_0, 10)
        if continue then
            if test_time~=nil then time_0=test_time end
        else
            temp_buffer:delete()
            return
        end
        ::next_filepath::
    end
    temp_buffer:delete()

    -- set up line_items for dialog:
    local line_items={}
    for k,v in pairs(related_lines) do
        local filepath,line_num=k[1],k[2]
        local filename, line_text=v[1],v[2]
        table.insert(line_items, filename)
        table.insert(line_items, line_text)
        table.insert(line_items, line_num)
        table.insert(line_items, filepath)
    end

    -- show dialog and goto definition in case of selection:
    local button,i=ui.dialogs.filteredlist{
        title = 'Goto related Keyline',
        columns = {'File', 'Text', 'Line', 'Filepath'},
        items = line_items,
        search_column=4}
    if button==1 and i then
        -- determine origin as current buffer together with current pos:
        local origin={buffer = buffer, pos = buffer.current_pos}
        -- jump to new line:
        local line_num=line_items[4*i-1]
        local filepath=line_items[4*i]
        ui.goto_file(filepath, false, _VIEWS[view], false)
        buffer:goto_line(line_num)
        tools.fit_into_view()
        return origin
    end
end
M.goto_related_keyline=goto_related_keyline



return M
