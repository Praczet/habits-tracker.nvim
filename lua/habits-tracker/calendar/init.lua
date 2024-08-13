local M = {}

M.habits = require("habits-tracker.calendar.habits")
M.barchart = require("habits-tracker.charting.bar")
M.utils = require("habits-tracker.utils")

M.setup = function(opts)
	if opts then
		M.habits.setup(opts)
		M.barchart.setup(opts)
	end
end

function M.test()
	local lines = M.habits.get_lines({
		{
			label = "French",
			data = { "2024-08-01", "2024-08-02", "2024-08-08" },
			style = { fg = "red" },
			symbol = "■",
		},
		{
			label = "Reading",
			data = { "2024-08-01", "2024-08-02", "2024-08-10" },
			style = { fg = "red" },
			symbol = "◆",
		},
		{
			label = "Self Development",
			data = { "2024-08-01", "2024-08-02", "2024-08-08", "2024-08-09", "2024-08-10" },
			style = { fg = "red" },
			symbol = "●",
		},
	}, { min = "2024-08-01", max = "2024-08-10" })
	M.habits.add_habit_to_buffer(lines)
end

return M
