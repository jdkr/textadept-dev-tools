local keylines={}


function keylines.get_patterns_for_attribute(name)
    if name==nil then name='\\S+' end

    local patterns={
        ['py']={
            '^\\s*class\\s+'..name..'.*\\:',
            '^\\s*def\\s+'..name..'\\s*\\(.*\\)\\s*\\:'},
        ['c']={  -- TODO: improve 'c'-patterns
            '^\\s*(static|int|float|double|char|void|struct|enum|bool)\\s+.*'
                ..name..'\\(.+\\)\\s*\\{',
            '^\\s*(static|int|float|double|char|void|struct|enum|bool)\\s+.*'
                ..name..'\\(.+\\)\\s*;',  --for prototypes
            --TODO: next-pattern can be removed if newlines will be included in whitespace:
            '^\\s*(static|int|float|double|char|void|struct|enum|bool)\\s+.*'
                ..name..'\\(.+\\)',
            '^\\s*(struct|union|enum|extern|typedef).*'..name..'.*;',
            '^\\s*#define\\s+.*'..name..'.*\\)'},
        ['hs']={
            '^\\s*'..name..'\\s+(::).*',
            '^\\s*(data|type|newtype|instance)\\s+.*'..name..'.*'},
        ['lua']={
            '^\\s*(local|)\\s*function\\s+\\S*'..name..'\\s*\\(.*\\)',
            '^\\s*(local|)\\s*'..name..'\\s*=\\s*function\\s*\\(.*\\)'}}

    -- additional patterns are useful for related keyline search (then is name~=nil and the number of found lines is therefore greatly reduced)
    if name~='\\S+' then
        local additional_patterns={
            ['lua']={'local\\s+'..name..'\\s*=.+'}}

        -- combine additional_patterns with patterns
        for ext,add_patts in pairs(additional_patterns) do
            for i=1,#add_patts do table.insert(patterns[ext], add_patts[i]) end
    end end
    return patterns
end

return keylines
