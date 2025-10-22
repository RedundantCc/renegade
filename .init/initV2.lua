local DIR_DELIM = DIR_DELIM or debug.getinfo(1, "S").source:match("[\\/]") or "/"
local modpath = minetest and core.get_modpath(core.get_current_modname()) or debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*)[/\\][^/\\]*$")
print (modpath)
local modname = minetest and core.get_current_modname() or modpath:match("[^\\/]+$")
print (modname)
local modinit = modpath .. DIR_DELIM .. modname..".lua"
print (modinit)
dofile(modinit)