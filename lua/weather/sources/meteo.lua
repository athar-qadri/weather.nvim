-- Import external libraries and modules:
local curl = require("plenary.curl") -- Used for making HTTP requests.
local desc = require("weather.assets.descriptions") -- Contains weather description mappings.
---@diagnostic disable-next-line: unused-local
local log = require("weather.log") -- Logging module (currently unused).

-- Define a Lua "class" for meteo functionality.
---@class meteo
---@field get fun(args: table, callback: fun(data: table))
local meteo = {}

--------------------------------------------------------------------------------
-- M.get_raw:
-- This function makes a raw HTTP GET request to the weather API.
-- It returns either:
--   - "success": a table with parsed JSON from the API,
--   - "failure": a table with an error message.
--------------------------------------------------------------------------------
meteo.get_raw = function(args, callback)
	-- Using plenary.curl to perform the HTTP GET request.
	curl.get({
		-- Uncommented example URL for USGS events is kept for reference.
		-- url = "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=2025-03-09T23:53:52&endtime=2025-03-09T23:53:59",
		url = "https://api.open-meteo.com/v1/forecast",
		query = args, -- Pass query parameters from the args.
		callback = function(response)
			-- Check if there was an error (non-zero exit code or HTTP error status).
			if response.exit ~= 0 or response.status > 400 or response.status < 200 then
				callback({
					failure = {
						message = response.body, -- Return the error message from the response.
					},
				})
				return
			end
			-- Use vim.schedule to ensure the JSON decoding runs on the main loop.
			vim.schedule(function()
				local response_table = vim.fn.json_decode(response.body)
				callback({
					success = response_table, -- Return the decoded JSON data.
				})
			end)
		end,
		-- on_error is called if curl fails to make the request.
		on_error = function()
			callback({
				failure = {
					message = "Oops, something went wrong", -- Generic error message.
				},
			})
		end,
	})
end

--------------------------------------------------------------------------------
-- get_icon:
-- This helper function determines the appropriate weather icon based on the
-- current weather code and whether it is day or night.
--------------------------------------------------------------------------------
local function get_icon(data, config)
	local id = data.current.weather_code -- Retrieve current weather code.
	local val = config.meteo.weather_code_to_icons[id] -- Map weather code to an icon identifier.
	local icons = config.weather_icons.night -- Default to night icons.
	if data.current.is_day == 1 then -- Check if it's day.
		icons = config.weather_icons.day -- Use day icons instead.
	end
	-- Return the specific icon if available, otherwise return the identifier.
	return icons[val] or val
end

--------------------------------------------------------------------------------
-- parse_weather_data:
-- Converts the raw data from the API into a Quake-specific formatted response.
-- It checks for errors, builds notifications, and formats the output string.
--------------------------------------------------------------------------------
---@param args Args table
local function parse_weather_data(data, args)
	local config = args.config
	local weather_config = args.weather_config
	local rev_geo_location = args.geo_location
	local location = args.location

	-- If the API returned an error, return a failure message.
	if data.failure then
		return {
			failure = {
				msg = "Oops, something went wrong",
			},
		}
	end

	-- Check for error details in the success response.
	if data.success.error then
		return {
			failure = {
				msg = data.success.reason or "Oops, something went wrong",
			},
		}
	end

	local notifications = {}
	local a = data.success

	-- Determine the correct weather icon using the helper function.
	local weather_icon = get_icon(data.success, weather_config)

	-- Calculate minimum width for the notification message.
	local min_width = require("notify.config").setup().minimum_width()
	local city = nil
	if rev_geo_location then
		city = rev_geo_location.suburb -- Use reverse geolocation to set city name.
	end

	-- Format the main weather data:
	local temp = a.current.temperature_2m
	local unit = string.upper(config.settings.temperature_unit:sub(1, 1))
	-- Choose description based on day/night.
	local weather_desc = desc[a.current.weather_code][(a.current.is_day == 1) and "day" or "night"].description
	-- Left part of the message includes temperature, unit, icon, and description.
	local left = string.format("%.1f°%s %s %s", temp, unit, weather_icon, weather_desc)
	-- Right part of the message includes high and low temperatures.
	local right = string.format("H:%.1f° L:%.1f°", a.daily.temperature_2m_max[1], a.daily.temperature_2m_min[1])
	local total_content_len = #left + #right
	local message
	-- Adjust spacing if the total message is shorter than the minimum width.
	if total_content_len + 1 <= min_width then
		local spaces_to_add = min_width - total_content_len
		message = left .. string.rep("  ", spaces_to_add) .. right
	else
		message = left .. " " .. right
	end

	local level = "warn" -- Notification level (e.g., warn, info, etc.).
	local options = { title = city or location.city } -- Title for the notification popup.

	-- Insert the formatted notification into the notifications table.
	table.insert(notifications, {
		message = message,
		level = level,
		options = options,
	})
	-- Return the final formatted data including both notification and data details.
	return {
		success = {
			alert = notifications,
			data = { condition_icon = weather_icon, temp = temp .. "°" .. unit },
		},
	}
end

---@class Args
---@field last_query_time number  -- Last query time in seconds
---@field callback fun(data: table)  -- Callback to be invoked with the result
---@field location any
---@field config WeatherConfig
---@field weather_config WeatherWeatherConfig
---@field geo_location any
--------------------------------------------------------------------------------
-- M.get:
-- This is the main function to fetch weather data.
-- It validates the input parameters, prepares the API query, and handles the
-- asynchronous response by invoking the callback with parsed data.
--------------------------------------------------------------------------------
---@param args Args table
meteo.get = function(args)
	-- Ensure the essential arguments are of the correct type.
	assert(type(args.last_query_time) == "number", "last_query_time must be a number")
	assert(type(args.callback) == "function", "callback must be a function")

	-- Prepare query parameters for the weather API.
	local params = {
		longitude = args.location.lon,
		latitude = args.location.lat,
		-- Request current weather details.
		current = "temperature_2m,apparent_temperature,is_day,precipitation,rain,weather_code",
		-- Request daily forecast details.
		daily = "temperature_2m_max,temperature_2m_min",
		temperature_unit = args.config.settings.temperature_unit,
	}
	-- Call get_raw with the prepared params, then process the result.
	meteo.get_raw(params, function(r)
		args.callback(parse_weather_data(r, args))
	end)
end

return meteo
