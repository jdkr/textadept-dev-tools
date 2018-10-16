-- NOTICE: Changes take effect after reset() or restart

local M = {}

-- view number where the output of run-, compile- and build-commands, as well
-- as the results of find_in_project and find_in_libraries is printed out.
-- If set to nil, then the current view is used to print:
M.preferred_view_idx=nil

-- goto lib indicates whether the function goto_related_keyline
-- should take the project-libraries into account:
M.goto_lib=false

-- when open a file that is contained in the project-libraries,
-- the buffer is set to read_only if this flag is set to true:
M.libs_read_only=true

-- Whether or not to activate customized keybindings.
-- If true default keybindings are overwritten:
M.select_word_extended_keybinding = true
M.join_lines_extended_keybinding = true
M.find_extended_keybinding = true
M.cut_extended_keybinding = true
M.goto_keyline_keybinding = true
M.goto_origin_keybinding = true
M.switch_print_buffers_keybinding = true
M.run_extended_keybinding = true
M.compile_extended_keybinding = true
M.build_extended_keybinding = true

return M
