-- Placeholder for line.lua
local M = {}
M.config = {}
function M.setup(config)
	M.config = vim.tbl_deep_extend("force", M.config, config)
end

return M
