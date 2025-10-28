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

local annotate_docs = {
	description =
	"Injects annotation wrappers around functions by automatically detecting function names and signatures. This function depends on debug.getinfo and may fail over to returning unwrapped or unsigned functions as a fallback in non-standard environments.",
	params = { "[documentation: table<description:string, params:string, returns:string>]", "func: function" },
	returns = "function: function with a meta table"
}
local annotate = function(doc, fn)
	if type(doc) == "function" then
		fn = doc
		doc = {}
	end
	local info = debug and debug.getinfo and debug.getinfo(fn, "S")
	local wrapper = {
		fn = fn,
		meta = {
			source = info and info.short_src,
			line = info and info.linedefined,
			doc = doc
		}
	}
	return setmetatable(wrapper, {
		__call = function(t, ...)
			return t.fn(...)
		end,
		__tostring = function(t)
			if t.meta.source and t.meta.line then
				return "Function@" .. t.meta.source .. ":" .. t.meta.line
			else
				return "Function!!Debug info unavailable!!"
			end
		end,
		__index = function(t, k)
			if k == "documentation" then
				return function(self)
					return self.meta.doc
				end
			end
			return t.meta[k]
		end
	})
end
library["annotate"] = annotate(annotate_docs, annotate)
--print(library["annotate"]:documentation())
--[[ === === == logging == === === ]] --
library["log"] = library["annotate"]({
	description =
	"A simplified cross-context logging function, designed to output quick debug messages before the actual logging function is loaded into memory. This function's definition should always yield to an existing version, preventing loss of state during hot reloading.",
	params = { "string:content" },
	returns = "nil"
}, function(content)

end)
--[[ === === ==  index  == === === ]] --
