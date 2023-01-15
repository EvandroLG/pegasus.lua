unused_args     = false
redefined       = false
max_line_length = false

globals = {
--    "ngx",
}

not_globals = {
    -- deprecated Lua 5.0 functions
    "string.len",
    "table.getn",
}

include_files = {
  "**/*.lua",
  "**/*.rockspec",
  ".busted",
  ".luacheckrc",
}

files["spec/**/*.lua"] = {
    std = "+busted",
}

exclude_files = {
    -- The Github Actions Lua Environment
    ".lua",
    ".luarocks",
    ".install",
}

