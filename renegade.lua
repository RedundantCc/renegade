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
annotate = function() error("use global version", 2) end
--REM print(library["annotate"]:documentation())

--[[ === === == logging == === === ]] --
library["INIT"] = INIT and INIT:lower():gsub("^game$", "server") or "lua"
library["log"] = library["log"] or library["annotate"]({
	description =
	"A simplified cross-context logging function, designed to output quick debug messages before the actual logging function is loaded into memory. This function's definition should always yield to an existing version, preventing loss of state during hot reloading.",
	params = { "any:..." },
	returns = "nil"
}, function(...)
	local info = debug and debug.getinfo and debug.getinfo(2, "Sl") or
		{ short_src = "", currentline = -1 } -- Level 2: caller of log()
	local args = { ... }
	for i = 1, #args do
		args[i] = tostring(args[i])
	end
	--if debug is unfucked inject with debug info, removed due to inconsistencies between server and csm output
	-- local _ = debug and debug.getinfo and table.insert(args, 1, string.format("[%s:%d]", info.short_src, info.currentline))
	--inject xsm type

	table.insert(args, 1, "[" .. library["INIT"]:upper() .. "]: ")
	local errorlevel = "error"
	local _ = minetest and (minetest.log(errorlevel, table.concat(args, " ")) or true) or
		print("" .. table.concat(args, " "))
end) --TODO:handle array conversion properly
local log = library["log"]
--REM log("test", 0, { "1", 2 })

--[[ === === ==  index  == === === ]] --
local get_folders = true
local get_files = false
library["index"] = library["annotate"]({
	description =
	"Index attempts to write index files containing a list of the files and folders for a given directory using minetest.get_dir or LuaFileSystem to index and io.* to write. Returns using the disc cache regardless of successful write. Is scheduled for potential breakages during luanti 2.0.0 upgrades.",
}, function(path, recursive)
	--patch function parameters and env
	if type(path) == "nil" then error("must provide valid path", 2) end
	recursive = recursive and true or false
	--TODO:add suport for std:environment
	--if not minetest then error("must be called by minetest", 0) end
	if minetest and not minetest.get_dir_list then return library["getindex"](path) end -- if is minetest but not has minetest.get_dir_list then is csm_restriction_flag_io and noop+return
	-- List all entries in the mod directory
	local nodelist = minetest and
		{ files = minetest.get_dir_list(path, get_files), folders = minetest.get_dir_list(path, get_folders) } or
		library["getindex"](path)
	local nodestri = "return " .. library["serialize"](nodelist)
	library["escribearchivo"](path .. DIR_DELIM .. "¯.lua", nodestri)
	--loop thu folders if parameter[2] == bool:true
	if recursive then
		for _, __ in ipairs(nodelist.folders) do
			--this does not save the return and only creates indexes, as this function can only return one value to the caller
			library["index"](path .. DIR_DELIM .. __, recursive)
			--TODO: return nil if recursive true to make usage clear.
		end
	end
	--return the contents of the newly written file
	return library["getindex"](path)
end)

library["getindex"] = library["annotate"]({
	description = "Returns the results of running index against a directory path."
}, function(path)
	return dofile(path .. DIR_DELIM .. "¯.lua")
end)

library["serialize"] = library["annotate"]({
	description = "Performs serialization on milk"
}, function(milk)
	local seen = {}
	local function quoteStr(str)
		return '"' .. str:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
	end
	local function formatKey(key)
		if type(key) == "string" and key:match("^[%a_][%w_]*$") then
			return key
		else
			return "[" .. quoteStr(tostring(key)) .. "]"
		end
	end
	local function formatValue(value, path)
		local var = type(value)
		if var == "string" then
			return quoteStr(value)
		elseif var == "boolean" or var == "number" then
			return tostring(value)
		elseif var == "table" then
			return serializeTable(value, path)
		else
			return '"<unsupported>"'
		end
	end
	local function isArray(param)
		local i = 1
		for _ in pairs(param) do
			if param[i] == nil then return false end
			i = i + 1
		end
		return true
	end
	function serializeTable(tab, path)
		if seen[tab] then
			return '"<circular>"'
		end
		seen[tab] = true
		path = path or {}
		local parts = {}
		local keys = {}
		for k in pairs(tab) do table.insert(keys, k) end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		if isArray(tab) then
			for i = 1, #tab do
				table.insert(parts, formatValue(tab[i], path))
			end
		else
			for _, k in ipairs(keys) do
				local v = tab[k]
				table.insert(parts, formatKey(k) .. "=" .. formatValue(v, path))
			end
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end

	return serializeTable(milk)
end)


local testTable = { a = "ah", bar = { "foo", 2 }, c = { level = "yes", ["false"] = true }, self = nil }
testTable.self = testTable -- Create circular reference
--REM log(library["serialize"](testTable))
assert(library["serialize"](testTable) == "{a=\"ah\",bar={\"foo\",2},c={false=true,level=\"yes\"},self=\"<circular>\"}")

-- Update a file only if its contents differ from the new content
library["escribearchivo"] = library["annotate"]({
	description = ""
}, function(filepath, content)
	if false then return nil end --TODO:block writes for testing
	if content == nil then
		local success, err = os.remove(filepath)
		if not success then
			local info = debug.getinfo(2, "Sl") -- 2 = caller of this function
			log("Failed to deallocate file: " .. err .. ", " .. info.short_src .. ":" .. info.currentline .. "")
			return false, err
		end
		return
	end
	-- Read current content as old_content
	local old_content = ""
	local f = io.open(filepath, "r")
	if f then
		old_content = f:read("*a")
		f:close()
	end
	-- Compare old_content and new_content write if has difference
	if old_content ~= content then
		f = io.open(filepath, "w")
		if f then
			f:write(content)
			f:close()
			return true                -- Indicates changes were written
		else
			local info = debug.getinfo(2, "Sl") -- 2 = caller of this function
			log("Failed to overwrite file, cannot open for writing: \"" ..
				filepath .. "\" " .. info.short_src .. ":" .. info.currentline)
			return false, err
		end
	end
	return false -- No changes made
end)

library["index"](modpath, false)
library["index"](modpath .. DIR_DELIM .. "src", true)
--[[ === === == dofiles == === === ]] --
-- dopath, executes every file in the top most directory of the provided path. For each file in this directory, dofile will be called and the return type evaluated. If the return type is a function it will be executed using any extra arguments [...] as it's calling arguments, if it is a string or array of strings<>TYPE(TABLE), it will be executed as a secondary file lookup, the value is returned as is otherwise.
--local _ = library["INIT"] ~= "lua" and library["dopath"](modpath .. DIR_DELIM .. "src" .. DIR_DELIM .. library["INIT"]) --load context library file
