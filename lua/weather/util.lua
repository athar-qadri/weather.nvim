local log = require("weather.log")
local M = {}

M.wrap_text = function(str, limit, indent, indent1)
	indent = indent or ""
	indent1 = indent1 or indent
	limit = limit or 72
	local here = 1 - #indent1
	local function check(_, st, word, fi)
		if fi - here > limit then
			here = st - #indent
			return "\n" .. indent .. word
		end
	end
	return indent1 .. str:gsub("(%s+)()(%S+)()", check)
end

M.data_to_message = function(data)
	log.debug(data)
end

return M
