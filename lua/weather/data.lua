local Path = require("plenary.path")
local os = require("os")
---@diagnostic disable-next-line: unused-local
local log = require("scratchpad.log")

local ensured_data_path = false
local data_path = string.format("%s/weather", vim.fn.stdpath("data"))

local function ensure_data_path()
	if ensured_data_path then
		return
	end
	local path = Path:new(data_path)
	if not path:exists() then
		path:mkdir()
	end
	ensured_data_path = true
end

local function fullpath()
	return string.format("%s/%s.json", data_path, "state")
end

local function write_data(data)
	Path:new(fullpath()):write(vim.json.encode({ context = data }), "w")
end

--- Reads the context from the filesystem, initializing it as an empty table if necessary
local function read_data()
	ensure_data_path()
	local path = Path:new(fullpath())
	if not path:exists() then
		local initial_data = {}
		write_data(initial_data)
		return initial_data
	end
	local out_data = path:read()
	if out_data == "" then
		local initial_data = {}
		write_data(initial_data)
		return initial_data
	end
	local data = vim.json.decode(out_data)
	return data.context or {}
end

---@alias Epoch number

---@class WeatherData
---@field has_error boolean
---@field config WeatherConfig
---@field update_source_data function
---@field data table<string, {last_query_time: Epoch}>
---@field fetch_context function
---@field update_last_query_time function
---@field get_last_query_time function

local M = {}
local Data = {}
Data.__index = Data

--- Creates a new Data instance, ensuring default sources are initialized
---@param config WeatherConfig
---@return WeatherData
function Data:new(config)
	local data = read_data()
	-- Ensure all default sources have an initial last_query_time
	for _, source in ipairs(config.default.default_sources) do
		if not data[source] then
			data[source] = { last_query_time = os.time() }
		end
	end
	return setmetatable({
		data = data,
		config = config,
	}, self)
end

--- Fetches the context from the filesystem
---@return boolean has_error True if an error occurred
function Data:fetch_context()
	local ok, data = pcall(read_data)
	if ok then
		self.data = data
	end
	return not ok
end

--- Updates the last query time for a specific source
---@param source string The source to update (e.g., "meteo", "usgs")
---@param new_time Epoch The new timestamp
function Data:update_last_query_time(source, new_time)
	if not self.data[source] then
		self.data[source] = { last_query_time = new_time }
	else
		self.data[source].last_query_time = new_time
	end
	write_data(self.data)
end

--- Retrieves the last query time for a specific source
---@param source string The source to query
---@return Epoch The last query time, or 0 if the source is new
function Data:get_last_query_time(source)
	if self.data[source] then
		return self.data[source].last_query_time
	else
		return 0 -- Indicates the source has never been queried
	end
end

M.Data = Data
return M
