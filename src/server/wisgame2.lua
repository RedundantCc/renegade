return function(library)
	local modname, modpath, DIR_DELIM = library.getmoddata("renegade")
	if string.startsWith(modname, "wis") then
		local srcpath = modpath .. DIR_DELIM .. "src" .. DIR_DELIM
		library["dopath"](srcpath .. "server" .. DIR_DELIM .. "wisgame2",
			function(path)
				--			library.log(path)
				--library.forfileaslines(path, function(linedata) library.log(linedata) end, true)
				library.registratefromfile(path)
			end, ".ini")
	end
end
