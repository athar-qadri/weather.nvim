-- Import external libraries and modules.
local curl = require("plenary.curl") -- For making HTTP requests.
local os = require("os") -- Provides operating system functions (e.g., date, time).
local log = require("weather.log") -- Logging module (currently not used).

-- Define module table.
local M = {}

--------------------------------------------------------------------------------
-- M.get_raw:
-- Performs a raw HTTP GET request to the USGS Earthquake API.
-- Returns a table containing either:
--   - "success": the parsed JSON response (as a Lua table), or
--   - "failure": a table with an error message.
--
-- @param args table: Query parameters to be sent with the API request.
-- @param callback fun(data: table): Callback function invoked with the result.
--------------------------------------------------------------------------------
M.get_raw = function(args, callback)
	curl.get({
		-- URL for USGS Earthquake API
		url = "https://earthquake.usgs.gov/fdsnws/event/1/query",
		query = args, -- Query parameters (e.g., format, starttime, etc.)
		callback = function(response)
			-- Check if curl reported an error or if the HTTP status is not in the 200 range.
			if response.exit ~= 0 or response.status > 400 or response.status < 200 then
				callback({
					failure = {
						message = response.body, -- Return error message from response.
					},
				})
				return
			end
			-- Schedule the JSON decoding and callback on the main loop.
			vim.schedule(function()
				local response_table = vim.fn.json_decode(response.body)
				callback({
					success = response_table, -- Return the decoded JSON data.
				})
			end)
		end,
		-- Called if curl encounters an error.
		on_error = function()
			callback({
				failure = {
					message = "It seems you are disconnected!", -- Generic error message.
				},
			})
		end,
	})
end

--------------------------------------------------------------------------------
-- parse_quake_data:
-- Maps the USGS earthquake API response to a formatted result.
-- If an error or no earthquake events are found, returns a failure message.
-- Otherwise, builds a list of notifications describing each earthquake event.
--
-- @param data table: API response table containing either a "success" or "failure" key.
-- @return table: A table containing either a "failure" key with an error message,
--                or a "success" key with an alert list.
--------------------------------------------------------------------------------
local function parse_quake_data(data)
	-- Check if the API call itself failed.
	if data.failure then
		return {
			failure = {
				msg = "Oops, something went wrong",
			},
		}
	end

	-- Check if the API response contains an error.
	if data.success.error then
		return {
			failure = {
				msg = data.success.reason or "Oops, something went wrong",
			},
		}
	end

	-- Process the successful response.
	if data.success then
		-- If the metadata count is 0, then no earthquake events were found.
		if data.success.metadata.count == 0 then
			return {}
			--return {
			--	failure = {
			--		msg = "No new Earthquakes",
			--	},
			--}
		end

		local notifications = {}
		-- Iterate over each earthquake feature in the response.
		for _, alert in ipairs(data.success.features) do
			-- Build the notification message string.
			local message = string.format(
				"Magnitude: %.1f\tCoordinates: %s\nPlace: %s\nTime: %s",
				alert.properties.mag,
				alert.geometry.coordinates[1] .. ", " .. alert.geometry.coordinates[2],
				alert.properties.place,
				-- Convert the timestamp (in milliseconds) to a human-readable date.
				os.date("%Y-%m-%d %H:%M:%S", alert.properties.time / 1000)
			)
			local level = "warn" -- Notification level.
			local options = { title = "Earthquake Alert" } -- Notification title.

			-- Create a notification entry.
			local notification = {
				message = message,
				level = level,
				options = options,
			}
			table.insert(notifications, notification)
		end

		return {
			success = {
				alert = notifications, -- List of formatted earthquake notifications.
			},
		}
	end
end

--------------------------------------------------------------------------------
-- Define a custom type for the arguments used by M.get.
-- @class USGSArgs
-- @field last_query_time number  -- Timestamp (in seconds) of the last query.
-- @field location any            -- Location information (if applicable).
-- @field config table            -- Configuration settings including minimum magnitude.
-- @field callback fun(data: table)  -- Callback function to return the result.
--------------------------------------------------------------------------------
---@class USGSArgs
---@field last_query_time number
---@field location table
---@field config table
---@field callback fun(data: table)
--------------------------------------------------------------------------------
-- M.get:
-- Main function to fetch earthquake data from the USGS API.
-- It builds the query parameters based on the input configuration and time,
-- then invokes M.get_raw. The parsed result (via parse_quake_data) is passed to the callback.
---@param args USGSArgs: A table containing the last query time, location, config, and callback.
--------------------------------------------------------------------------------
M.get = function(args)
	-- Extract parameters from the args table.
	local last_query_time = args.last_query_time
	local location = args.location
	local config = args.config

	-- Retrieve minimum magnitude from config settings; use default if not provided.
	local minimum_magnitude = config.settings.minimum_magnitude or config.default.minimum_magnitude

	-- Prepare query parameters for the USGS API.
	local params = {
		format = "geojson",
		orderby = "time-asc",
		starttime = os.date("!%Y-%m-%dT%TZ", last_query_time), -- Format last query time in UTC.
		endtime = os.date("!%Y-%m-%dT%TZ", os.time()), -- Current UTC time.
		minmagnitude = minimum_magnitude,
		longitude = location.lon,
		latitude = location.lat,
		----maxradius = 181,
		maxradiuskm = 500,
	}
	-- Invoke the raw API call and pass the parsed result to the provided callback.
	M.get_raw(params, function(r)
		args.callback(parse_quake_data(r))
	end)
end

return M
