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
	library["positiontochunkindex"] = function (position)
	    local chunk_size = 16
	    local chunk_index_x = math.floor(position[1] / chunk_size)
	    local chunk_index_y = math.floor(position[2] / chunk_size)
	    local chunk_index_z = math.floor(position[3] / chunk_size)
	    return {chunk_index_x, chunk_index_y, chunk_index_z}
	end
end
