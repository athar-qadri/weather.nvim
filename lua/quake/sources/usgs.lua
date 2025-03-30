local curl = require("plenary.curl")
local os = require("os")
local log = require("quake.log")

local M = {}

-- Does a raw call to openweathermap, returning a table with either:
-- "success": table containing the parsed json response from https://openweathermap.org/api/one-call-api
-- "failure": string with the error message
---@diagnostic disable-next-line: unused-local
M.get_raw = function(args, callback)
	curl.get({
		--url = "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=2025-03-09T23:53:52&endtime=2025-03-09T23:53:59",
		url = "https://earthquake.usgs.gov/fdsnws/event/1/query",
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
					message = "It seems you are disconnected!",
				},
			})
		end,
	})
end

-- Maps a quaka data object to a Quake object.
local function parse_quake_data(data, config, location)
	print(vim.inspect(data))
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
				msg = data.success.reason or "Oops, something went wrong",
			},
		}
	end

	if data.success then
		--print(vim.inspect(usgs.success.metadata))
		if data.success.metadata.count == 0 then
			return {}
			--return {
			--	failure = {
			--		msg = "No new Earthquakes",
			--	},
			--}
		end

		local notifications = {}
		if data.success and data.success.metadata.count > 0 then
			for _, alert in ipairs(data.success.features) do
				local message, level, options =
					string.format(
						"Magnitude: %.1f\tCoordinates: %s\nPlace: %s\nTime: %s",
						alert.properties.mag,
						alert.geometry.coordinates[1] .. ", " .. alert.geometry.coordinates[2],
						alert.properties.place,
						os.date("%Y-%m-%d %H:%M:%S", alert.properties.time / 1000)
					),
					"warn",
					{ title = "Earthquake Alert" }

				local notification = {
					message = message,
					level = level,
					options = options,
				}
				table.insert(notifications, notification)
			end
		else
			table.insert(notifications, {
				message = "No new earthquakes.",
				level = "info",
				options = { title = "Earthquake Update" },
			})
		end

		return {
			success = {
				alert = notifications,
			},
		}
	end
end

---@diagnostic disable-next-line: unused-local
M.get = function(last_query_time, geo_location, location, config, weather_config, callback)
	local minimum_magnitude = config.settings.minimum_magnitude or config.default.minimum_magnitude
	local diffs = os.difftime(os.time(), last_query_time)
	--local diffs = math.abs(os.time() - last_query_time)

	if diffs < (config.settings.update_interval / 1000) then
		return
	end

	local args = {
		format = "geojson",
		orderby = "time-asc",
		starttime = os.date("!%Y-%m-%dT%TZ", last_query_time),
		endtime = os.date("!%Y-%m-%dT%TZ", os.time()),
		minmagnitude = minimum_magnitude,
		--longitude = location.lon,
		--latitude = location.lat,
		----maxradius = 180,
		--maxradiuskm = 40,
	}
	M.get_raw(args, function(r)
		callback(parse_quake_data(r, config, location))
	end)
end

return M
