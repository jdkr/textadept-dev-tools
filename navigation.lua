local M = {}

local is_files_found_buffer=function(buf) return buf._type == _L['[Files Found Buffer]'] end
M.is_files_found_buffer=is_files_found_buffer
local is_message_buffer=function(buf) return buf._type == _L['[Message Buffer]'] end
M.is_message_buffer=is_message_buffer
local is_print_buffer=function(buf)
    return (is_files_found_buffer(buf) or is_message_buffer(buf))
end
M.is_print_buffer=is_print_buffer

-- Switching back inside a view from a print-buffer to the last previous buffer which was not a print-buffer. Function returns a boolean if there was a switch:
local switch_back_from_print_buffers = function(view_buffer_state)
    local switched=false
    local switch_back_buffer=nil
    -- TODO (Maybe): switch only back if inside print-buffer
    for i=1,#_VIEWS do
        -- check if there is a buffer to switch back:
        if is_print_buffer(_VIEWS[i].buffer) then
            -- switch if there is a buffer stored for the view and this buffer exists in _BUFFERS:
            switch_back_buffer=view_buffer_state[_VIEWS[i]]
            if _BUFFERS[switch_back_buffer] then
                view.goto_buffer(_VIEWS[i], view_buffer_state[_VIEWS[i]])
                switched=true
            end
        end
    end
    -- if there was a switch of buffers switch also the view:
    if switched==true then
        if view_buffer_state.focus_view then ui.goto_view(view_buffer_state.focus_view) end
    end
    -- return boolean for or operator in extension of 'esc'-keybinding:
    return switched
end
M.switch_back_from_print_buffers=switch_back_from_print_buffers

-- Updates the view_buffer_state, with current_state:
local prepare_print=function(view_buffer_state)
    -- snap ui-state
    local buffer_in_view=nil
    local focus=nil
    for i=1,#_VIEWS do
        buffer_in_view=_VIEWS[i].buffer
        if not is_print_buffer(buffer_in_view) then
            view_buffer_state[_VIEWS[i]]=buffer_in_view
            focus = _VIEWS[i] == view
            if focus then view_buffer_state.focus_view=_VIEWS[i] end
        end
    end
    --switch to preferred_view where print-out should take place
    local preferred_view=_VIEWS[view_buffer_state.preferred_view_idx]
    if preferred_view~=nil then ui.goto_view(preferred_view) end

    -- return modified view_buffer_state
    return view_buffer_state
end
M.prepare_print=prepare_print

return M
