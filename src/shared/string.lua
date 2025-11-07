-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String
return function(library)
	--	local modname, modpath, DIR_DELIM = library.getmoddata("renegade")

	string.startsWith = library.annotate(
		{ description = "Determines whether the calling string begins with the characters of string searchString." },
		function(p1Haystack, p2Needle) -- self == haystack, p2Needle == searchString
			return p1Haystack:sub(1, #p2Needle) == p2Needle
		end)

	string.endsWith = library.annotate(
		{ description = "Determines whether a string ends with the characters of the string searchString." },
		function(p1Haystack, p2Needle) -- self == haystack, p2Needle == searchString
			return p1Haystack:match(p2Needle:gsub("(%p)", "%%%1") .. "$") ~= nil
		end)

	string.charAt = library.annotate(
		{
			description = "Returns the character (exactly one UTF-8 code unit) at the specified index. " ..
				"Accepts negative integers, which count back from the last string character."
		}, function(p1Haystack, p2Index)
			p2Index = p2Index < 0 and #p1Haystack + p2Index + 1 or p2Index
			return (p2Index >= 1 and p2Index <= #p1Haystack) and p1Haystack:sub(p2Index, p2Index) or nil
		end)

	string.charCodeAt = library.annotate(
		{
			description = "Returns a number that is the UTF-8 code unit value at the given index."
		}, function(p1Haystack, p2Index)
			local returns = p1Haystack:charAt(p2Index)
			return returns and returns:byte() or nil
		end)

	string.includes = library.annotate({ description = "Determines whether the calling string contains searchString." },
		function(p1Haystack, p2Needle)
			if type(p1Haystack) ~= "string" or type(p2Needle) ~= "string" then
				error("Both parameters must be of type string")
			end
			return p1Haystack:find(p2Needle, 1, true) ~= nil
		end)


	string.charCount = library.annotate({ description = "" }, function(p1Haystack, p2Char)
		local count = 0
		for _ in string.gmatch(p1Haystack, p2Char) do
			count = count + 1
		end
		return count
	end)
	string.trim = library.annotate({ description = "Trims whitespace from the beginning and end of the string." },
		function(p1Haystack)
			return p1Haystack:match("^%s*(.-)%s*$") or p1Haystack
		end)
	string.trimStart = library.annotate({ description = "Trims whitespace from the beginning of the string." },
		function(p1Haystack)
			return p1Haystack:match("^%s*(.-)$") or p1Haystack
		end)
	string.trimEnd = library.annotate({ description = "Trims whitespace from the end of the string." },
		function(p1Haystack)
			return p1Haystack:match("^(.-)%s*$") or p1Haystack
		end)
	--string.test = library.annotate({ description = "" }, function(p1Haystack, p2Index) end)
end
