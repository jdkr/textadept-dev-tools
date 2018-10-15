local M={}


local function trim(str)
    return string.match(str,'%S.*%S') or string.match(str,'%S') or ''
end
M.trim=trim

local function split(s,separator)
    --TODO: Doesn't work with '.' as separator
    local result = {}
    for match in (s..separator):gmatch("(.-)"..separator) do
        table.insert(result, match)
    end
    return result
end
M.split=split

local function startswith(str, start_str)
    if string.sub(str,1,#start_str)==start_str then return true else return false end end
M.startswith=startswith

local function endswith(str, end_str)
    if string.sub(str,#str-#end_str+1,#str)==end_str then return true else return false end end
M.endswith=endswith

local function shrink_whitespace(str)
    local str=string.gsub(str,"\n"," ")
    local replacements=1
    while replacements>0 do
        str,replacements=string.gsub(str,"  "," ")
    end
    return str
end
M.shrink_whitespace=shrink_whitespace

local function split_path(path)
    local dir,filename,extension=string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
    return dir, filename, extension
end
M.split_path=split_path


return M
