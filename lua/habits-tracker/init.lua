local M = {}

-- Load modules
M.charting = require("habits-tracker.charting")
M.calendar = require("habits-tracker.calendar")
M.journal = require("habits-tracker.journal")

-- Any initialization code
M.setup = function(opts)
	-- Set up each module with user-provided options or defaults
	M.charting.setup(opts.charting or {})
	M.calendar.setup(opts.calendar or {})
	M.journal.setup(opts.journal or {})
end

function M.test()
	vim.notify("Test triggered")
end

return M
