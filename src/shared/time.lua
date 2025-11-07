return function(library)
	local modname, modpath, DIR_DELIM = library.getmoddata("renegade")
	library["sleep"] =
		function(seconds)
			local _ = minetest or require("socket").sleep(seconds)
		end
end
