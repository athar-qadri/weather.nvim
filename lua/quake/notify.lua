local quake = require("quake")
local notify = require("notify")

local result = {}

result.start = function(text_wrap, notify_level, notify_opts)
	local wrap = text_wrap or 70
	local l = notify_level or "error"
	local opts = notify_opts or {
		icon = "⚠️",
	}
	notify:setup({
		--minimum_width = 60, -- Set the minimum width for notifications
		stages = "fade",
		timeout = 5000,
		top_down = false,
		background_colour = "#000000",
	})
	quake:subscribe("notify", function(data)
		if data.failure then
			return
		end

		if not next(data) then
			return
		end

		--print("notifing" .. vim.inspect(data))

		if data.success and data.success.alert then
			local delay = 0
			for _, alert in ipairs(data.success.alert) do
				notify(alert.message, alert.level, alert.options)
			end
		end
	end)
end

return result
