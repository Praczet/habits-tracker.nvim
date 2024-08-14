-- Placeholder for init.lua
local M = {}

M.config = {}

M.parser = require("habits-tracker.journal.parser")

M.setup = function(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	M.parser.setup(M.config)
end

function M.get_habits(start_date, end_date, habits)
	return M.parser.get_habits(start_date, end_date, habits)
end

function M.test(min, max, value)
	return M.parser.test(min, max, value)
end

return M
