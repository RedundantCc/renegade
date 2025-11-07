return function(library)
	local modname, modpath, DIR_DELIM = library.getmoddata("renegade")
	function table.contains(table, needle)
		for _, value in ipairs(table) do
			if value == needle then
				return true
			end
		end
		return false
	end

	function table.equals(table1, table2)
		--easy way
		if table1 == table2 then return true end
		if type(table1) ~= "table" or type(table2) ~= "table" then return false end
		--hard way
		for key1, value1 in pairs(table1) do
			if table2[key1] == nil then
				return false
			end
			-- Compare tables recursively if both values are of type table
			if type(value1) == "table" and type(table2[key1]) == "table" then
				if not table.equals(value1, table2[key1]) then
					return false
				end
			else
				if value1 ~= table2[key1] then
					return false
				end
			end
		end
		return true
	end
end
