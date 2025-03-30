local Path = require("plenary.path")
local os = require("os")
---@diagnostic disable-next-line: unused-local
local log = require("scratchpad.log")

local ensured_data_path = false

local data_path = string.format("%s/quake", vim.fn.stdpath("data"))

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

--- @class QuakeData
--- @field has_error boolean
--- @field config QuakeConfig
--- @field update_source_data function
--- @field last_query_time Epoch
--- @field update_last_query_time function
--- @field data QuakeContext
--- @field fetch_context function

---@class QuakeContext
--- @field last_query_time Epoch

local M = {}
local Data = {}

Data.__index = Data

local function read_data()
	ensure_data_path()

	local path = Path:new(fullpath())
	local exists = path:exists()

	local epoch = os.time() -- Use number instead of string
	if not exists then
		local initial_data = { last_query_time = epoch }
		write_data(initial_data)
		return initial_data
	end

	local out_data = path:read()
	if out_data == "" then
		local initial_data = { last_query_time = epoch }
		write_data(initial_data)
		return initial_data
	end

	local data = vim.json.decode(out_data)
	return data.context
end

---@alias Epoch number

---update last query time in fs
---@param new_time Epoch
function Data:update_last_query_time(new_time)
	if not self.data then
		self:fetch_context()
	end
	self.data.last_query_time = new_time
	write_data(self.data)
end

function Data:fetch_context()
	local ok, data = pcall(read_data)
	if ok then
		self.data = data
	end
	return not ok
end

---@param config QuakeConfig
---@return QuakeData
function Data:new(config)
	log.debug("new data", config)
	self:fetch_context()
	return setmetatable({
		data = nil,
		config = config,
	}, self)
end

M.Data = Data

return M
