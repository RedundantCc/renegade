return function(library)
	local modname, modpath, DIR_DELIM = library.getmoddata("renegade")

	library["forfileaslines"] = function(filePath, funcHandle, ignoreReturn)
		local file = io.open(filePath, "r")
		--if file is context:open then
		local returns = {}
		if not file then
			error("access error: reading non-existant file, @" .. filePath)
		end
		if file then
			--itarate over each line and pass to funkyFunc
			for line in file:lines() do
				local linedata = line:trim()                     --:sub(1,-2) --remove spooky char at the end of a line. If file uses \r\n, it may require (1,-3)
				linedata = funcHandle and (funcHandle(linedata)) or linedata --buggy:TODO
				--this data subject to brakeages, test for errors here:
				--print("<"..linedata..">")
				if not ignoreReturn then --used for large files, to avoid memory bloat.
					table.insert(returns, linedata)
				end
			end
			file:close()
			return returns
		else
			return {}
		end
	end



	library["forfileasiniobj"]        = function(filePath, ignoreHeaders)
		local debug_print = false
		local returns = {} --object to store data about ini file as a hashmap table
		returns[""] = {} --default object to store global values before a header tag('[' or ']') is found in the file stream
		local rpointer = "" -- by default pointer set to "" by default
		local linenum = 0
		local _ = library["forfileaslines"](filePath, function(line)
			linenum = linenum + 1
			--in ini, ';' may be used as a comment by default.
			--in the future this may be abstracted into a larger function with more customization
			if not (line:trim():startsWith(";") or line:trim() == "") then --discard comments or empty lines
				--if is header "[*]"
				local _ = debug_print and print(line)
				if line:match("^%[.*%]$") then
					if not ignoreHeaders then
						rpointer = line:sub(2, -2):trim() --remove [ and ] from the header and use as str:returnPointer
						returns[rpointer] = returns[rpointer] or {}
					end
					--else if is key value pair "*=*"
				elseif line:match("^.+=.+$") and line:charCount("=") == 1 then
					local spointerarray = line:split("=")
					spointerarray[1] = spointerarray[1]:trim()
					spointerarray[2] = spointerarray[2]:trim()
					--If parser fails due to missing '"', use raw string as a fall back.
					--minetest.parse_json create an unmutable error with no way to prevent it,
					--just return as string ill deal with this later.			 :(
					--Upon reflection this function should always return a string,
					--since it may be used in multiple use case and so should leave parsing decisions to the caller
					--_G[context].parse(spointerarray[2]) or
					returns[rpointer][spointerarray[1]] = spointerarray[2]
				else --else is error
					error(table.concat({ "error reading: ", filePath, "@^", linenum, "$" }, ""))
				end
			end
		end, true)
		--if the global array table was never used, delete it.
		if #returns[""] == 0 and true then
			returns[""] = nil
		end
		return returns
	end

	library["registrateitemfromblob"] = function(blob)
		assert(blob["name"] ~= nil)
		if not blob["name"]:find(":") then
			blob["name"] = table.concat({ core.get_current_modname(), blob["name"] }, ":")
		end
		blob["type"] = "none"
		local localname = blob["name"]
		blob["name"] = nil
		if blob["tool_dig_groups"] then
			blob["tool_capabilities"] = blob["tool_capabilities"] or {}
			blob["tool_capabilities"]["groupcaps"] = blob["tool_capabilities"]["groupcaps"] or {}
			for _, value in ipairs(blob["tool_dig_groups"]) do
				blob["tool_capabilities"]["groupcaps"][value] = {
					times = blob["tool_dig_times"] or nil,
					uses = blob["tool_dig_uses"] or nil,
					maxlevel = blob["tool_dig_maxlevel"] or nil
				}
			end
			blob["tool_capabilities"]["damage_groups"] = blob["tool_capabilities"]["damage_groups"] or nil
		end
		--print(">>",blob["tool_damage_groups"])
		minetest.register_item(localname, blob)
		--print(">>", minetest.write_json({[1] = 0.00, [2] = 2.00, [3] = 3.0, [100] = 99.0}))
	end
	local registratebiomefromblob     = function(blob)
		assert(blob["name"] ~= nil)
		if not blob["name"]:find(":") then
			blob["name"] = table.concat({ core.get_current_modname(), blob["name"] }, ":")
		end
		if blob["depth_top"] == nil and blob["node_top_depth"] ~= nil then
			blob["depth_top"] = blob["node_top_depth"]
			--blob["node_top_depth"]=nil
		end
		if blob["depth_filler"] == nil and blob["node_filler_depth"] ~= nil then
			blob["depth_filler"] = blob["node_filler_depth"]
			blob["node_filler_depth"] = nil
		end
		if blob["depth_riverbed"] == nil and blob["node_riverbed_depth"] ~= nil then
			blob["depth_riverbed"] = blob["node_riverbed_depth"]
			blob["node_riverbed_depth"] = nil
		end
		local yMin = -31000
		local yMax = 31000
		local oMin = blob["y_min"] or yMin
		local oMax = blob["y_max"] or yMax
		local seaLevel = minetest.settings:get("water_level") or 1
		blob["y_min"] = blob["dune_line"] or seaLevel
		blob["y_max"] = oMax

		if blob["node_riverbed"] ~= nil or blob["node_substratum"] ~= nil then
			blob["node_riverbed"] = blob["node_riverbed"] or blob["node_substratum"] or nil
			blob["node_substratum"] = blob["node_substratum"] or blob["node_riverbed"] or nil
		end
		if blob["node_riverbed"] == nil then
			minetest.register_biome(blob)
		else
			minetest.register_biome(blob)
			blob["name"] = table.concat({ blob["name"], "_subterranean" }, "")
			--e3.s
			blob["node_top"] = blob["node_riverbed"]
			blob["depth_top"] = blob["depth_riverbed"] or 1
			blob["node_filler"] = blob["node_substratum"]
			blob["depth_filler"] = blob["node_substratum_depth"] or 1

			blob["y_max"] = blob["y_min"] - 1
			blob["y_min"] = oMin
			--print(blob)

			minetest.register_biome(blob)
		end
		--node_riverbed = "mapgen_sand"
		--node_riverbed_depth = 3

		--node_substratum="mapgen_sandstone"
		--node_substratum_depth=1
	end
	local registratetoolfromblob      = function(blob)
		assert(blob["name"] ~= nil)
		if not blob["name"]:find(":") then
			blob["name"] = table.concat({ core.get_current_modname(), blob["name"] }, ":")
		end
		blob["type"] = "none"
		local localname = blob["name"]

		blob["type"] = nil
		minetest.register_tool(localname, blob)
	end

	local function unregisternodesbyalias(alias)
		--library.log("Unregistered alias: " .. alias)
		for name, def in pairs(minetest.registered_nodes) do
			if def.alias and def.alias == alias then
				library.log("Unregistered node: " .. name)
				minetest.unregister_node(name)
			end
		end
	end
	local registratenodefromblob  = function(blob)
		local nodeName = blob["name"]
		blob["name"] = nil
		assert(nodeName ~= nil)
		if not nodeName:find(":") then
			nodeName = table.concat({ core.get_current_modname(), nodeName }, ":")
		end
		local nodeAlias = blob["alias"]
		blob["alias"] = nil
		core.register_node(nodeName, blob)
		if type(nodeAlias) == "string" then
			unregisternodesbyalias(nodeAlias)
			core.register_alias(nodeAlias, nodeName)
		elseif type(nodeAlias) == "table" then
			for key, value in ipairs(nodeAlias) do
				unregisternodesbyalias(value)
				core.register_alias(value, nodeName)
			end
		else
		end

		local wah = minetest.registered_nodes[nodeName].groups
	end
	library["registratefromfile"] = function(filePath)
		--library.log("** " .. filePath)
		for header, data in pairs(library["forfileasiniobj"](filePath, false)) do
			--library.log("***" .. filePath)
			for k, v in pairs(data) do
				data[k] = minetest.parse_json(v) --_G[modname].parse(v)
			end
			if data["type"] == nil then
				error("expectation not met, missing type in file:" .. filePath)
			end
			assert(type(data["type"]) == "string")
			local types = { "node", "item", "tool", "biome", "craft" }
			if not table.contains(types, data["type"]) then
				error("expectation not met, invalid type in file:" .. filePath)
			end
			if data["type"] == "node" then
				data["type"] = nil
				registratenodefromblob(data)
			end
			if data["type"] == "item" then
				data["type"] = nil
				registratebiomefromblob(data)
			end
			if data["type"] == "tool" then
				data["type"] = nil
				registratetoolfromblob(data)
			end
			if data["type"] == "biome" then
				data["type"] = nil
				registratebiomefromblob(data)
			end
		end
	end
end
