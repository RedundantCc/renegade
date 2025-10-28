--[[ === ====    cache    ==== === ]] --
local library = c and { cache = c["cache"], log = c["log"] } or {}
local cache = {}
library["usecache"] = library["cache"] or function(get, set)
	cache[get] = cache[get] or set
	return cache[get]                 -- can return null
end
--[[ === ====   moddata   ==== === ]] --
library["getmoddata"] = function(modname)
	local caller = (debug and debug.getinfo and debug.getinfo(2, "n").name) or (debug and debug.getinfo and "global") or
		modname -- this may result in undefined/untested behavior on_error if called from the global scope, is probably fine.
	assert(type(modname) == "string" and #modname > 0,
		"Erroneous call in '" .. caller .. "': value must be a string of len > 0")
	local modname = minetest and core.get_current_modname() or
		debug.getinfo(2, "S").source:gsub("^@", ""):match("^[%.%/\\]*(.-)[/\\][^/\\]*$")
	local modpath = minetest and core.get_modpath(core.get_current_modname()) or
		debug.getinfo(2, "S").source:gsub("^@", ""):match("^(.*)[/\\][^/\\]*$")
	cache[modname .. "_modname"] = modname
	cache[modname .. "_modpath"] = modpath
	return cache[modname .. "_modname"], cache[modname .. "_modpath"], DIR_DELIM or modpath:match("[\\/]") or "/"
end
local modname, modpath, DIR_DELIM = library.getmoddata("renegade")

--[[ ===    manpage methods    === ]] --
