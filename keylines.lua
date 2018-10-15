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


--[[
Patterns from Atom-Plugin (UNTESTET!!!)

module.exports =
  'JavaScript (JSX)':
    regex: [
      "(^|\\s|\\.){word}\\s*[:=]\\s*function\\s*\\("
      "(^|\\s)function\\s+{word}\\s*\\("
      "(^|\\s){word}\\([\\s\\S]*?\\)\\s*{"  # ES6
      "(^|\\s)class\\s+{word}(\\s|$)"
    ]
    type: ["*.jsx", "*.js", "*.html"]

  CoffeeScript:
    regex: [
      "(^|\\s)class\\s+{word}(\\s|$)"
      "(^|\\s|\\.){word}\\s*[:=]\\s*(\\([\\s\\S]*?\\))?\\s*[=-]>"
      "(^|\\s|\\.){word}\\s*[:=]\\s*function\\s*\\(" # JavaScript Function
      "(^|\\s)function\\s+{word}\\s*\\("
      "(^|\\s){word}\\([\\s\\S]*?\\)\\s*{"  # ES6
    ]
    type: ["*.coffee", "*.js", "*.html"]

  TypeScript:
    regex: [
      "(^|\\s)class\\s+{word}(\\s|$)"
      "(^|\\s|\\.){word}\\s*[:=]\\s*(\\([\\s\\S]*?\\))?\\s*[=-]>"
      "(^|\\s|\\.){word}\\s*[:=]\\s*function\\s*\\(" # JavaScript Function
      "(^|\\s)function\\s+{word}\\s*\\("
      "(^|\\s){word}\\([\\s\\S]*?\\)\\s*{"  # ES6
    ]
    type: ["*.ts", "*.html"]

  Python:
    regex: [
      "(^|\\s)class\\s+{word}\\s*\\("
      "(^|\\s)def\\s+{word}\\s*\\("
    ]
    type: ["*.py"]


  PHP:
    regex: [
      "(^|\\s)class\\s+{word}(\\s|{|$)"
      "(^|\\s)interface\\s+{word}(\\s|{|$)"
      "(^|\\s)(static\\s+)?((public|private|protected)\\s+)?(static\\s+)?function\\s+{word}\\s*\\("
    ]
    type: ["*.php"]

  Hack:
    regex: [
      "(^|\\s)class\\s+{word}(\\s|{|$)"
      "(^|\\s)interface\\s+{word}(\\s|{|$)"
      "(^|\\s)(static\\s+)?((public|private|protected)\\s+)?(static\\s+)?function\\s+{word}\\s*\\("
    ]
    type: ["*.hh"]

  Ruby:
    regex: [
      "(^|\\s)class\\s+{word}(\\s|$)"
      "(^|\\s)module\\s+{word}(\\s|$)"
      "(^|\\s)def\\s+(?:self\\.)?{word}\\s*\\(?"
      "(^|\\s)define_method\\s+:?{word}\\s*\\(?"
    ]
    type: ["*.rb"]

  KRL:
    regex: [
      "(^|\\s)DEF\\s+{word}\\s*\\("
      "(^|\\s)DECL\\s+\\w*?{word}\\s*\\=?"
      "(^|\\s)(SIGNAL|INT|BOOL|REAL|STRUC|CHAR|ENUM|EXT|\\s)\\s*\\w*{word}.*"
    ]
    type: ["*.src","*.dat"]

  Perl:
    regex: [
      "(^|\\s)sub\\s+{word}\\s*\\{"
      "(^|\\s)package\\s+(\\w+::)*{word}\\s*\\;"
    ]
    type: ["*.pm","*.pl"]

  'C/C++':
    regex: [
      "(^|\\s)class\\s+{word}(\\s|:)"
      "(^|\\s)struct\\s+{word}(\\s|{|$)"
      "(^|\\s)enum\\s+{word}(\\s|{|$)"
      "(^|\\s)#define\\s+{word}(\\s|\\(|$)"
      "(^|\\s)typedef\\s.*(\\s|\\*|\\(){word}(\\s|;|\\)|$)"
      "^[^,=/(]*[^,=/(\\s]+\\s*(\\s|\\*|:|&){word}\\s*\\(.*\\)(\\s*|\\s*const\\s*)({|$)"
    ]
    type: ["*.c","*.cc","*.cpp","*.h","*.hh","*.hpp","*.inc"]
--]]
