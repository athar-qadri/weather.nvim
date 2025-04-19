local curl = require("plenary.curl")
local Config = require("quake.config")
local weather_config = require("quake.sources.weather.config").default
local Data = require("quake.data")
local notify = require("notify")
---@diagnostic disable-next-line: unused-local
local log = require("quake.log")

---@class Quake
---@field config QuakeConfig
---@field weather_config QuakeWeatherConfig
---@field data QuakeData
---@field subscribers table
---@field update_source_data function
---@field location_lookup function
---@field subscribe function
---@field last_update table
local Quake = {}

Quake.__index = Quake

local timer = nil
local subscriptions = {}

---@return Quake
function Quake:new()
	local config = Config.get_default_config()

	local quake = setmetatable({
		config = config,
		weather_config = weather_config,
		data = Data.Data:new(config),
		subscribers = {},
	}, self)

	return quake
end

function Quake:__debug_reset()
	require("plenary.reload").reload_module("quake")
end

function Quake:unsubscribe(id)
	table[id] = nil
end

---subscribe function
---@param id string
---@param callback function
function Quake:subscribe(id, callback)
	assert(type(callback) == "function", "Callback must be a function")
	if id == "weather_now" then
		self:unsubscribe(id)
	end
	assert(subscriptions[id] == nil, "Subscribed to weather updates with existing id: " .. id)
	subscriptions[id] = callback
	if self.last_update then
		callback(self.last_update)
	end
end

---location lookup from ip address
---@param callback function
function Quake:location_lookup(callback)
	curl.get({
		url = "http://ip-api.com/json?fields=status,country,countryCode,region,regionName,city,zip,lat,lon",
		--url = "http://ip-api.com/json/191.48.0.1",
		--url = "https://httpbin.org/delay/5",
		timeout = 5,
		callback = function(response)
			vim.schedule(function()
				if response.exit ~= 0 or response.status >= 400 or response.status < 200 then
					callback({
						failure = {
							message = response.body,
						},
					})
					return
				end
				local response_table = vim.fn.json_decode(response.body)
				callback({
					success = {
						country = response_table.country,
						region = response_table.regionName,
						city = response_table.city,
						lat = response_table.lat,
						lon = response_table.lon,
					},
				})
			end)
		end,
		on_error = function()
			callback({
				failure = {
					message = "Error",
				},
			})
		end,
	})
end

function Quake:get_data_with_location(context, geo_location, location)
	--print("get data with loc" .. vim.inspect(geo_location))
	for _, source in ipairs(self.config.default.default_sources) do
		local object = require("quake.sources." .. source)
		local last_query_time = context[source].last_query_time

		--local diffs = os.difftime(os.time(), last_query_time)
		--if diffs < (config.settings.update_interval / 1000) then
		--	return
		--end

		local args = {
			last_query_time = last_query_time,
			geo_location = geo_location,
			location = location,
			config = self.config,
			weather_config = self.weather_config,
			callback = function(data)
				if data.failure then
					self.last_update = data
					notify(data.failure.msg, "error", { title = "Error" })
					return
				end
				self.last_update = data
				--print("...")
				--print(vim.inspect(subscriptions))
				--print("...")
				for _, v in pairs(subscriptions) do
					--print("data from get location" .. vim.inspect(data))
					v(data)
				end

				if data and data.success then
					vim.schedule(function()
						self.data:update_last_query_time(source, os.time())
					end)
				end
			end,
		}
		local _ = object.get(args)
	end
end

---reverse geo lookup for location
---@param location any
---@param callback function
local function geo_reverse_lookup(location, callback)
	--print("start of geo look" .. vim.inspect(location))
	curl.get({
		url = "https://nominatim.openstreetmap.org/reverse",
		timeout = 5,
		query = {
			format = "json",
			lat = location.lat,
			lon = location.lon,
			zoom = 18,
			addressdetails = 1,
			["accept-language"] = "en",
		},
		callback = function(response)
			vim.schedule(function()
				if response.exit ~= 0 or response.status >= 400 or response.status < 200 then
					callback({
						failure = {
							message = response.body,
						},
					})
					return
				end
				local response_table = vim.fn.json_decode(response.body)
				callback({
					success = {
						name = response_table.name,
						suburb = response_table.address.suburb,
						city = response_table.address.city,
					},
				})
			end)
		end,
		on_error = function()
			callback({
				failure = {
					message = "Error",
				},
			})
		end,
	})
end

function Quake:update_source_data()
	local context = self.data.data -- self.data.data is the context table
	local rev_geo_location = {}

	if self.config.settings.location then
		--print("location is available in config")
		geo_reverse_lookup(self.config.settings.location, function(data)
			--print("geo lookup done")
			if data.success then
				rev_geo_location = {
					name = data.success.name,
					city = data.success.city,
					suburb = data.success.suburb,
				}
			end
			self:get_data_with_location(context, rev_geo_location, self.config.settings.location)
		end)
	else
		self:location_lookup(function(location_response)
			if location_response.success then
				--print("location response is success")
				self:get_data_with_location(context, nil, location_response.success)
			else
				notify("No internet connection", "error", { title = "Error" })
				--for _, s in pairs(subscriptions) do
				--	s(location_response)
				--end
			end
		end)
	end
end

local the_quake = Quake:new()

---Sets up the configuration and begins fetching weather/earthquake data.
---@param self Quake
---@param partial_config QuakePartialConfig?
---@return Quake
function Quake.setup(self, partial_config)
	if self ~= the_quake then
		---@diagnostic disable-next-line: cast-local-type
		partial_config = self
		self = the_quake
	end

	local config = self.config
	---@diagnostic disable-next-line: param-type-mismatch
	self.config = Config.merge_config(partial_config, config)

	vim.schedule(function()
		if not timer then
			timer = vim.loop.new_timer()
			timer:start(0, self.config.settings.update_interval, function()
				self:update_source_data()
			end)
		end
	end)

	return self
end

vim.api.nvim_create_user_command("WeatherNow", function()
	local quake = require("quake")
	quake:update_source_data()
end, {})

return the_quake
