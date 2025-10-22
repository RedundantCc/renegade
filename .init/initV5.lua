local modpath = minetest and core.get_modpath(core.get_current_modname()) or debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*)[/\\][^/\\]*$")
dofile(modpath .. (DIR_DELIM or (debug and debug.getinfo and debug.getinfo(1, "S").source:match("[\\/]") or "/")) .. modpath:match("[^\\/]+$")..".lua")
