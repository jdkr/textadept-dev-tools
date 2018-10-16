local settings = require "textadept-dev-tools.settings"
local tools = require "textadept-dev-tools.tools"
local tools_project = require "textadept-dev-tools.tools_project"
local nav = require "textadept-dev-tools.navigation"


-- Initialize local variables for navigation.
-- view_buffer_state is used to control the prints from run- und build commands and the print from Findings. It stores 3 type of information:
-- 1. the preferred_view_idx where the printings should take place
-- 2. the focus_view that had focus before printing
-- 3. for every view before print it saves the current_buffer of the view (but only if it's no printing-buffer)
local view_buffer_state={preferred_view_idx = settings.preferred_view_idx}
-- origin saves the buffer and position before a goto_keyline or goto_related_keyline is called:
local origin={buffer = buffer, pos = buffer.current_pos}

-- keybindings:
local keys, OSX, GUI, CURSES, _L = keys, OSX, not CURSES, CURSES, _L
if settings.select_word_extended_keybinding == true then
    keys[not OSX and (GUI and 'cD' or 'mW') or 'mD'] = tools.select_word_extended
end
if settings.join_lines_extended_keybinding == true then
    keys[not OSX and (GUI and 'cJ' or 'mj') or 'cj'] = tools.join_lines_extended
end
if settings.find_extended_keybinding == true then
    keys[not OSX and GUI and 'cf' or 'mf'] = tools.find_extended
end
if settings.cut_extended_keybinding == true then
    keys[not OSX and 'cx' or 'mx'] = tools.cut_extended
end

local goto_keyline_call=function() origin=tools.goto_keyline() end
if settings.goto_keyline_keybinding == true then
    keys[not OSX and GUI and 'cg' or 'mg'] = goto_keyline_call
end

local goto_origin_call = function() tools.goto_origin(origin) end
if settings.goto_origin_keybinding == true then
    keys[not OSX and GUI and 'cG' or 'mG']= goto_origin_call
end

-- For all Views, if the current Buffer is a Print-Buffer (i.e. Find_in_Files_Buffer, Message_Buffer), then switch to the previous Buffer that wasn't a Print-Buffer.
local switch_print_buffers_call = function()
    return nav.switch_print_buffers(view_buffer_state)
end
if settings.switch_print_buffers_keybinding==true then
    keys['ca\n'] = switch_print_buffers_call
end

-- Extension of Run- Compile- and Build-commands with detection of view_buffer_state:
local run_extended_call = function()
    view_buffer_state=nav.prepare_print(view_buffer_state)
    textadept.run.run()
end
local compile_extended_call = function()
    view_buffer_state=nav.prepare_print(view_buffer_state)
    textadept.run.compile()
end
local build_extended_call = function()
    view_buffer_state=nav.prepare_print(view_buffer_state)
    textadept.run.build()
end

-- Extended keybindings for run- and compile-commands:
if settings.run_extended_keybinding == true then
    keys[not OSX and 'cr' or 'mr'] = run_extended_call
end
if settings.compile_extended_keybinding == true then
    keys[not OSX and (GUI and 'cR' or 'cmr') or 'mR'] = compile_extended_call
end
if settings.build_extended_keybinding == true then
    keys[not OSX and (GUI and 'cB' or 'cmb') or 'mB'] = build_extended_call
end

-- key-sequences (accessible via alt+d):
keys['ad'] = {}
keys['ad']['o'] = {}
keys['ad']['o']['s'] = tools.open_settings
keys['ad']['r'] = {}
keys['ad']['r']['f'] = tools.rename_file
keys['ad']['l'] = {}
keys['ad']['l']['p'] = tools_project.load_project
keys['ad']['n'] = {}
keys['ad']['n']['p'] = tools_project.new_project

--Adding project-item to menu:
local SEPARATOR = {''}
local dev_tools_menu = {
    title = 'Dev-Tools',
    {'Settings ...', tools.open_settings},
    SEPARATOR,
    {'Rename File', tools.rename_file},
    {'Goto Keyline', goto_keyline_call},
    {'Goto Origin', goto_origin_call},
    {'Switch Print Buffers', switch_print_buffers_call},
    {'Find extended', tools.find_extended},
    {'Select Word extended', tools.select_word_extended},
    {'Join Lines extended', tools.join_lines_extended},
    {'Cut extended', tools.cut_extended},
    SEPARATOR,
    {title = 'Project',
        {'Load', tools_project.load_project},
        {'New', tools_project.new_project}},
    SEPARATOR,
    {'Run extended', run_extended_call},
    {'Compile extended', compile_extended_call},
    {'Build extended', build_extended_call}
}
local mbar = textadept.menu.menubar
mbar[#mbar + 1] = dev_tools_menu
textadept.menu.context_menu[#textadept.menu.context_menu + 1] = dev_tools_menu


-- function to create additional Keybindings and Menu-items for project with project filename:
local init_project=function(project_filename)
    -- dofile does a similar job like require, see lua-doc
    local project=dofile(tools_project.PROJECTS_DIR..project_filename)
	if project==nil then return end

	-- libs of Project:
    local lib_filepaths=tools_project.get_lib_filepaths(project)

    -- connection that ensures that files that are contained in lib_filepaths are opened read-only by default if settings.libs_read_only=true:
    events.connect(events.FILE_OPENED, function()
        if lib_filepaths[buffer.filename]==true then
            buffer.read_only = settings.libs_read_only
        end
    end)

    -- call functions for keybindings and menu-items:
    local unload_project_call = function()
        tools_project.unload_project() end
    local config_project_call = function()
        tools_project.configure_project() end
    local quick_open_project_call = function()
        io.quick_open(project.dir, project.filter) end
    local find_in_project_call = function()
        local search_text=tools_project.get_search_text('Find in Project')
        if search_text~=nil and search_text~=''  then
            view_buffer_state=nav.prepare_print(view_buffer_state)
            tools_project.find_in_project(project, search_text)
        end
    end
    local find_replace_in_project_call = function()
        view_buffer_state=nav.prepare_print(view_buffer_state)
        tools_project.find_replace_in_project(project)
    end
    local find_in_libs_call = function()
        local search_text=tools_project.get_search_text('Find in Libraries')
        if search_text~=nil and search_text~=''  then
            view_buffer_state=nav.prepare_print(view_buffer_state)
            tools_project.find_in_libs(project, search_text)
        end
    end
    local quick_open_libs_call = function()
        tools_project.quick_open_libs(project) end
    local close_lib_buffers_call = function()
        tools_project.close_lib_buffers(lib_filepaths)
    end
    local goto_related_keyline_call = function()
        origin=tools_project.goto_related_keyline(project, settings.goto_lib)
    end
    local run_project_call = function()
        view_buffer_state=nav.prepare_print(view_buffer_state)
        tools_project.run_project(project)
    end
    local compile_project_call = function()
        view_buffer_state=nav.prepare_print(view_buffer_state)
        tools_project.compile_project(project)
    end
    local build_project_call = function()
        view_buffer_state=nav.prepare_print(view_buffer_state)
        tools_project.build_project(project)
    end

    -- project related keybindings (notice: run- and compile-keybindings are redirected):
    keys['ad']['u'] = {}
    keys['ad']['u']['p'] = unload_project_call
    keys['ad']['q'] = {}
    keys['ad']['c'] = {}
    keys['ad']['c']['p'] = config_project_call
    keys['ad']['q']['o'] = {}
    keys['ad']['q']['o']['p'] = quick_open_project_call
    keys['ad']['q']['o']['l'] = quick_open_libs_call
    keys['ad']['f'] = {}
    keys['ad']['f']['i'] = {}
    keys['ad']['f']['i']['p'] = find_in_project_call
    keys['ad']['r']['i'] = {}
    keys['ad']['r']['i']['p'] = tools_project.replace_in_project
    keys['ad']['f']['r'] = {}
    keys['ad']['f']['r']['i'] = {}
    keys['ad']['f']['r']['i']['p'] = find_replace_in_project_call
    keys['ad']['f']['i']['l'] = find_in_libs_call
    keys['ad']['c']['l'] = {}
    keys['ad']['c']['l']['b'] = close_lib_buffers_call
    keys['f12'] = goto_related_keyline_call

    if settings.run_extended_keybinding == true then
        keys[not OSX and 'cr' or 'mr'] = run_project_call
    end
    if settings.compile_extended_keybinding == true then
        keys[not OSX and (GUI and 'cR' or 'cmr') or 'mR'] = compile_project_call
    end
    if settings.build_extended_keybinding == true then
        keys[not OSX and (GUI and 'cB' or 'cmb') or 'mB'] = build_project_call
    end

    --Project menu add_items:
    dev_tools_menu[#dev_tools_menu-4]=
    {title = 'Project',
        {'Unload', unload_project_call},
        {'New', tools_project.new_project},
        {'Configure', config_project_call},
        {'Quick open', quick_open_project_call},
        SEPARATOR,
        {'Find in Project', find_in_project_call},
        {'Replace in Project', tools_project.replace_in_project},
        {'Find+Replace in Project', find_replace_in_project_call},
        SEPARATOR,
        {'Find in Libraries', find_in_libs_call},
        {'Quick open in Libraries', quick_open_libs_call},
        {'Close Library Buffers', close_lib_buffers_call},
        SEPARATOR,
        {'Goto related Keyline', goto_related_keyline_call},
        SEPARATOR,
        {'Run Project', run_project_call},
        {'Compile Project', compile_project_call},
        {'Build Project', build_project_call}}

    -- remove previous run-, compile- and build-keybindings from menu if there is a project:
    dev_tools_menu[#dev_tools_menu]=nil
    dev_tools_menu[#dev_tools_menu]=nil
    dev_tools_menu[#dev_tools_menu]=nil
end

-- initialization of current_project. If there is an error, show a dialog:
local project_filename=tools_project.get_current_project()
if project_filename~='' then
    local status, err = pcall(function() init_project(project_filename) end)
    if status==false then
        ui.dialogs.msgbox{title='Error', text='No valid project\n\n'..err}
    end
end


