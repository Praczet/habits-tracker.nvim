-- Placeholder for init.lua
local M = {}

M.config = {}

M.parser = require("habits-tracker.journal.parser")
M.utils = require("habits-tracker.utils")

local function get_journal_path(date)
	local file_name = os.date(M.config.day_format, M.utils.get_os_time(date))
	return vim.fn.expand(M.config.journals .. "/" .. file_name)
end
local function load_template()
	return M.utils.read_file(vim.fn.expand(M.config.tmpl_daily))
end
--
-- Function to create a journal file with replaced content
local function create_journal_file(path, date, replacements)
	local template = load_template()
	if not template then
		return
	end

	-- Replace ##day## with the actual date
	template = template:gsub("##day##", date)

	-- Replace other placeholders with corresponding values or empty strings
	for placeholder, value in pairs(replacements) do
		template = template:gsub("##" .. placeholder .. "##", value)
	end

	-- Replace any remaining placeholders with empty strings
	template = template:gsub("##%w+##", "")

	-- Write the processed template to the file
	path = vim.fn.expand(path)
	local file = io.open(path, "w")
	if file then
		file:write(template)
		file:close()
	else
		vim.notify("Failed to create journal file: " .. path .. "", vim.log.levels.ERROR)
	end
end

function M.create_journal(date, replacements)
	-- Get the journal file path
	local journal_path = get_journal_path(date)

	-- Check if the journal file exists
	if M.utils.file_exists(journal_path) then
		-- Open the file if it exists
		vim.cmd("edit " .. journal_path)
	else
		-- Create the file with the template and then open it
		create_journal_file(journal_path, date, replacements)
		vim.cmd("edit " .. journal_path)
	end
end

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
