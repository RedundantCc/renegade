function config(filepath, query_key, set_value)
	local result = nil
	local lines = {}
	local key_found = false
	-- Read lines
	local file = io.open(filepath, "r")
	if file then
		for line in file:lines() do
			-- Respect comments
			if line:match("^%s*(.-)%s*$"):sub(1, 1) == "#" then
				table.insert(lines, line)
			else
				local key, value = line:match("^%s*(.-)%s*=%s*(.-)%s*$")
				if key and value then
					if key == query_key then
						key_found = true
						if set_value ~= nil then
							table.insert(lines, key .. " = " .. set_value)
							result = set_value
						else
							table.insert(lines, line)
							result = value
						end
					else
						table.insert(lines, line)
					end
				else
					table.insert(lines, line) -- preserve malformed lines
				end
			end
		end
		file:close()
	end
	-- If the key wasn't found and set_value is set, add new value.
	if not key_found and set_value ~= nil then
		table.insert(lines, query_key .. " = " .. set_value)
		result = set_value
	end
	-- Write the data to the file if set_value is set.
	if set_value ~= nil then
		file = io.open(filepath, "w")
		if file then
			for _, l in ipairs(lines) do
				file:write(l .. "\n")
			end
			file:close()
		end
	end
	return result
end

function basedir(path)
	return path:match("^(.*)[/\\][^/\\]*$") or ""
end
function basename(path)
	return path:match("([^/\\]+)$") or path
end

function sanitize(str)
	return str:lower():gsub("[^%w]", "_")
end

local lfs = minetest or ({pcall(require, "lfs")})[2]
local function currentdir()
	if type(lfs) == "string" then
		local source = debug.getinfo(2, "S").source:gsub("^@", "")
		return source:match("^(.*)[/\\][^/\\]*$") or "."
	else
		lfs.currentdir()
	end
	--	local currentdir = lfs and type(lfs)=="table" and lfs.currentdir and lfs.currentdir() or ""
end

local DIR_DELIM = DIR_DELIM or debug.getinfo(1, "S").source:match("[\\/]") or "/"
--local log = minetest and function(...) minetest.log("error", table.concat({...}, " ")) end or print
local log = minetest and function(...) minetest.log("error", INIT:lower():gsub("(%a)(%w*)", function(first, rest)	return first:upper() .. rest	end) ..":	"..table.concat({...}, " ")) end or print
local modname, modpath = (function()
	local mt_name = minetest and core.get_current_modname() or nil
	local mt_path = minetest and core.get_modpath(mt_name) or nil
	if minetest then return mt_name, mt_path end
	-- This only executes if running externally
	local ex_path = currentdir()
	local ex_name = config(ex_path..DIR_DELIM.."mod.conf", "name")..""-- .."/daBreakageT3sT* _"
	local ex_ohno = sanitize(basename(ex_path)) 
	--log("ex_path:"..ex_path)
	--log("ex_name:"..ex_name)
	--log("ex_ohno:"..ex_ohno)
-- Note that modifications made to files in a virtual machine are not guaranteed to be persistent.
	local _ = (ex_ohno~=ex_name) and config(ex_path..DIR_DELIM.."mod.conf", "name", ex_ohno) 
	--log(_)
--title
	return ex_name, ex_path
end) ()
local csm_restriction_flag_io = (minetest and minetest.get_dir_list and true or false)
--##  --  ^ Never used? ^   --  --  --##  --  --  --  --##  --  --  --##  --  --  --  --
local function searchdir(path)
	local files = {}
	local lfs = ({pcall(require, "lfs")})[2]
	if type(lfs) == "table" then
		--Use LuaFileSystem
		for file in lfs.dir(path) do
			if file ~= "." and file ~= ".." then
				table.insert(files, file)
			end
		end
	elseif type(io) == "table" and type(io.popen) == "function" then
		--Fallback to shell command
		local cmd = package.config:sub(1,1) == "\\" and
					('dir "%s" /b'):format(path) or
					('ls -1 "%s"'):format(path)
		local handle = io.popen(cmd)
		if handle then
			for file in handle:lines() do
				table.insert(files, file)
			end
			handle:close()
		else
			--log("Could not get directory via shell.")
			return { "init.lua", modname..".lua" }
		end
	else
		--log("Neither lfs nor io.popen available.")
		return { "init.lua", modname..".lua" }
	end
	return files
end

function filter(list, condition)
    local result = {}
    for _, value in ipairs(list) do
        if condition(value) then
            table.insert(result, value)
        end
    end
    return result
end


local filelist = searchdir(".")
      filelist = filter(filelist, function(file)	return file:match("%.lua$") and file ~= "init.lua"	end)
if #filelist ~= 1 then
	log("Could not auto-rename code file, expected one other %.lua$ file.")
	log("Found " .. #filelist .. " file(s):")
	for _, file in ipairs(filelist) do
		log("  - " .. file)
	end
elseif filelist[1] ~=  table.concat({modname, ".lua"}) then
	--Require build step
	if not minetest then 
		-- Rename file if needed
		log(table.concat({"move",filelist[1], modname .. ".lua"}, " "))
		local success, err = os.rename(modpath .. DIR_DELIM .. filelist[1],  modpath .. DIR_DELIM .. modname .. ".lua")
		assert(success, "["..modname.."] Failed to rename '" .. filelist[1] .. "': " .. tostring(err))
	else
		log("Rename file "..filelist[1].."not supported!") 
	end
end

local LOAD_ME = table.concat({modpath, DIR_DELIM, modname, ".lua" }, "")
--log(LOAD_ME)
--Exit if running in stand alone mode.
local _ = minetest and dofile(LOAD_ME)

