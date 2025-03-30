---@diagnostic disable-next-line: unused-local
local log = require("quake.log")
local M = {}

---@class QuakePartialConfigItem
---@field minimum_radius? number
---@field minimum_magnitude? number
---@field update_interval number
---@field default_sources? table

---@class QuakeSettings
---@field update_interval Epoch
---@field temperature_unit string
---@field location? any

---@class QuakePartialSettings
---@field update_interval Epoch
---@field temperature_unit string

---@class QuakePartialConfig
---@field defaults? QuakePartialConfigItem
---@field setting? QuakePartialSettings
---@field [string] QuakePartialConfigItem

---@class QuakeConfig
---@field settings QuakeSettings
---@field default QuakePartialConfigItem

function M.get_config(config, name)
	return vim.tbl_extend("force", {}, config.default, config[name] or {})
end

---@param partial_config QuakePartialConfig?
---@param latest_config QuakeConfig?
---@return QuakeConfig
function M.merge_config(partial_config, latest_config)
	partial_config = partial_config or {}
	local config = latest_config or M.get_default_config()
	for k, v in pairs(partial_config) do
		if k == "settings" then
			config.settings = vim.tbl_extend("force", config.settings, v)
		elseif k == "default" then
			config.default = vim.tbl_extend("force", config.default, v)
		else
			config[k] = vim.tbl_extend("force", config[k] or {}, v)
		end
	end
	return config
end

M.get_default_config = function()
	return {
		settings = {
			update_interval = 200 * 1000, -- 15 Minutes in ms
			temperature_unit = "celsius",
			--temperature_unit = "fahrenheit",
		},
		default = {
			minimum_magnitude = 4.0,
			minimum_radius = 20, -- in kms

			update_interval = 20 * 1000, -- 15 Minutes in ms
			--update_interval = 15 * 60 * 1000, -- 15 Minutes in ms
			default_sources = { "meteo", "usgs" },
			--	weather_icons = default_icons(),
		},
	}
end

return M
