local modpath = minetest and core.get_modpath(core.get_current_modname()) or debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*)[/\\][^/\\]*$")
dofile(modpath .. (DIR_DELIM or (modpath:match("[\\/]") or "/")) ..((minetest and core.get_current_modname() or modpath:match("[^\\/]+$"))..".lua"))
