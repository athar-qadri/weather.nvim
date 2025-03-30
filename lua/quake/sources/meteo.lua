local curl = require("plenary.curl")
local desc = require("quake.assets.descriptions")
local os = require("os")
---@diagnostic disable-next-line: unused-local
local log = require("quake.log")

local M = {}

-- Does a raw call to openweathermap, returning a table with either:
-- "success": table containing the parsed json response from https://openweathermap.org/api/one-call-api
-- "failure": string with the error message
---@diagnostic disable-next-line: unused-local
M.get_raw = function(args, callback)
	--print("meteo get raw")
	curl.get({
		--url = "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=2025-03-09T23:53:52&endtime=2025-03-09T23:53:59",
		url = "https://api.open-meteo.com/v1/forecast",
		query = args,
		callback = function(response)
			if response.exit ~= 0 or response.status > 400 or response.status < 200 then
				callback({
					failure = {
						message = response.body,
					},
				})
				return
			end
			vim.schedule(function()
				local response_table = vim.fn.json_decode(response.body)
				callback({
					success = response_table,
				})
			end)
		end,
		on_error = function()
			callback({
				failure = {
					message = "Oops, something went wrong",
				},
			})
		end,
	})
end

local function get_icon(meteo, config)
	local id = meteo.current.weather_code
	local val = config.meteo.weather_code_to_icons[id]
	local icons = config.weather_icons.night
	if meteo.current.is_day == 1 then
		icons = config.weather_icons.day
	end
	return icons[val] or val
end

-- Maps a quaka data object to a Quake object.
local function parse_weather_data(data, config, weather_config, rev_geo_location, location)
	--print("parse_weather_data")
	if data.failure then
		return {
			failure = {
				msg = "Oops, something went wrong",
			},
		}
	end
	if data.success.error then
		return {
			failure = {
				msg = data.success.reason or "68Oops, something went wrong",
			},
		}
	end

	local notifications = {}
	local a = data.success

	-- a.current.apparent_temperature,
	-- a.current.interval,
	-- a.current.is_day,
	-- a.current.precipitation,
	-- a.current.rain,
	-- a.current.temperature_2m,
	-- a.current.time,
	-- a.daily.temperature_2m_max[1],
	-- a.daily.temperature_2m_min[1],
	-- a.current.weather_code,

	local weather_icon = get_icon(data.success, weather_config)

	local min_width = require("notify.config").setup().minimum_width()
	local city = nil
	--print("parse weather geo loca" .. vim.inspect(rev_geo_location))

	if rev_geo_location then
		city = rev_geo_location.name
	end

	local temp = a.current.temperature_2m
	local unit = string.upper(config.settings.temperature_unit:sub(1, 1))
	local weather_desc = desc[a.current.weather_code][(a.current.is_day == 1) and "day" or "night"].description
	local left = string.format("%.1f°%s %s %s", temp, unit, weather_icon, weather_desc)

	local right = string.format("H:%.1f° L:%.1f°", a.daily.temperature_2m_max[1], a.daily.temperature_2m_min[1])
	local total_content_len = #left + #right
	local message
	if total_content_len + 1 <= min_width then
		local spaces_to_add = min_width - total_content_len
		message = left .. string.rep("  ", spaces_to_add) .. right
	else
		message = left .. " " .. right
	end
	local level = "warn"
	--print(vim.inspect(location))
	local options = { title = city or location.city }

	table.insert(notifications, {
		message = message,
		level = level,
		options = options,
	})
	return {
		success = {
			alert = notifications,
			data = { condition_icon = weather_icon, temp = temp .. "°" .. unit },
		},
	}
end

---comment
---@param last_query_time Epoch
---@param rev_geo_location any
---@param location any
---@param config QuakeConfig
---@param weather_config QuakeWeatherConfig
---@param callback any
M.get = function(last_query_time, rev_geo_location, location, config, weather_config, callback)
	--print("meteo get")
	local diffs = os.difftime(os.time(), last_query_time)

	--if diffs < (config.settings.update_interval / 1000) then
	--	return
	--end

	local args = {
		longitude = location.lon,
		latitude = location.lat,
		current = "temperature_2m,apparent_temperature,is_day,precipitation,rain,weather_code",
		daily = "temperature_2m_max,temperature_2m_min",
		temperature_unit = config.settings.temperature_unit,
	}
	M.get_raw(args, function(r)
		callback(parse_weather_data(r, config, weather_config, rev_geo_location, location))
	end)
end

return M
