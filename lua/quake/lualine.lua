local quake = require("quake")
local log = require("quake.log")
local util = require("quake.util")

local function default_c_formatter(data)
	if data ~= nil then
		return data.condition_icon .. "" .. data.temp
	end
end

local result = {}
-- A helper function for displaying items on lualine. A (verbose) example usage of this in your init.vim may be:
--
--local function format(data)
--  return data.condition_icon .. " " .. math.floor(data.temp.f) .. "°F"
--end
--
--require('lualine').setup {
--  sections = {
--    ...
--    lualine_x = { custom(format) },
--  }
--}

result.custom = function(formatter, alt_icons)
	local default_icons = {
		pending = "⏳",
		error = "❌",
	}
	local icons = vim.tbl_extend("force", default_icons, alt_icons or {})
	local text = icons.pending
	quake:subscribe("lualine", function(update)
		if update.failure then
			text = alt_icons.error
		else
			if update.success then
				text = formatter(update.success.data)
			end
			vim.schedule(function()
				vim.api.nvim_command("redrawstatus")
			end)
		end
	end)
	return function()
		return text
	end
end

result.default_c = function(pending)
	return result.custom(default_c_formatter, pending)
end

return result
