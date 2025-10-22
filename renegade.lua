--[[ === ====    cache    ==== === ]]--
local library = c and {cache = c["cache"], log=c["log"]} or {}
local cache = {}
library["usecache"] = library["cache"] or function (get, set)
	cache[get] = cache[get] or set
	return cache[get] -- can return null
end
