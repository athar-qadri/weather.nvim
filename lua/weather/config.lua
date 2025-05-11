---@diagnostic disable-next-line: unused-local
local log = require("weather.log")
local M = {}

---@class WeatherPartialConfigItem
---@field minimum_radius? number
---@field minimum_magnitude? number
---@field update_interval number
---@field default_sources? table

---@class WeatherSettings
---@field update_interval Epoch
---@field temperature_unit string
---@field location? any

---@class WeatherPartialSettings
---@field update_interval Epoch
---@field temperature_unit string

---@class WeatherPartialConfig
---@field defaults? WeatherPartialConfigItem
---@field setting? WeatherPartialSettings
---@field [string] WeatherPartialConfigItem

---@class WeatherConfig
---@field settings WeatherSettings
---@field default WeatherPartialConfigItem

function M.get_config(config, name)
	return vim.tbl_extend("force", {}, config.default, config[name] or {})
end

---@param partial_config WeatherPartialConfig?
---@param latest_config WeatherConfig?
---@return WeatherConfig
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
