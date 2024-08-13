-- Placeholder for init.lua
local M = {}

M.line = require("habits-tracker.charting.line")
M.bar = require("habits-tracker.charting.bar")

M.setup = function(opts)
	-- Configuration for the charting module
end

function M.test()
	--- Testing barchar
	local chart_data = {
		y_label = "Weight",
		x_label = "",
		max_rows = 10,
		add_aprox = true,
		x_min = "2024-08-01",
		x_max = "2024-08-07",
		max_height_value = 0.8,
		title = "Weight (kg) 2024-08-01 - 2024-08-07",
		data = {
			{ type = "exact", value = 120, x = "2024-08-04" },
			{ type = "exact", value = 100, x = "2024-08-01" },
			-- { type = "aprox", value = 110, x = "2024-08-02" }, -- example, this would be interpolated if missing
		},
	}
	M.bar.vertical(chart_data)
	M.bar.horizontal(chart_data)
end
return M
