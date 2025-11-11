return function(library)
	local modname, modpath, DIR_DELIM = library.getmoddata("renegade")
	library["chunkindextobounds"] = function(chunk_index)
	-- Calculate the lower bounds
	local min_x = chunk_index[1] * core.MAP_BLOCKSIZE
	local min_y = chunk_index[2] * core.MAP_BLOCKSIZE
	local min_z = chunk_index[3] * core.MAP_BLOCKSIZE

	-- Calculate the upper bounds
	local max_x = min_x + core.MAP_BLOCKSIZE - 1
	local max_y = min_y + core.MAP_BLOCKSIZE - 1
	local max_z = min_z + core.MAP_BLOCKSIZE - 1

	return vector.new(min_x, min_y, min_z), vector.new(max_x, max_y, max_z)
end
