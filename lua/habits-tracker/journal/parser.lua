-- Placeholder for parser.lua
local M = {}
local lyaml_exists, lyaml = pcall(require, "lyaml")

M.config = {}
M.utils = require("habits-tracker.utils")

-- local variables
--- full path to the journal
local journals_dir = nil
local default_symbol = "●"

-- Local functions

local function get_days_files(start_date, end_date)
	if not start_date or not end_date then
		M.utils.log_message("journal.parser.get_days_files", "Mid Date or Max Date not provided")
		vim.notify("Required arguments are not provided", vim.log.levels.ERROR)
		return
	end
	if start_date > end_date then
		M.utils.log_message("journal.parser.get_days_files", "Min Date is greater than Max Date")
		vim.notify("Min Date is greater than Max Date", vim.log.levels.ERROR)
		return
	end
	local files = {}
	local dates = M.utils.generate_dates_in_range(start_date, end_date)
	local file_format = M.config.day_format or "%Y-%m-%d.md"
	for _, date in pairs(dates) do
		local filename = os.date(file_format, M.utils.get_os_time(date))
		local full_path = journals_dir .. "/" .. filename
		if M.utils.file_exists(full_path) then
			table.insert(files, full_path)
		end
	end
	return files
end

local function get_symbol_from_habit(habit)
	if not M.config and not M.config.habits then
		return default_symbol
	end
	for _, v in pairs(M.config.habits) do
		if v.label == habit then
			return v.symbol
		end
	end
end

local function get_habits_from_values(values)
	if not values then
		return {}
	end
	-- {
	-- 	label = "French",
	-- 	data = { "2024-08-01", "2024-08-02", "2024-08-08" },
	-- 	style = { fg = "red" },
	-- 	symbol = "■",
	-- },
	local habits = {}
	for k, v in pairs(values) do
		local habit = { label = k, data = {}, symbol = get_symbol_from_habit(k) }
		for _, d in pairs(v) do
			if d.value then
				table.insert(habit.data, d.date)
			end
		end
		table.insert(habits, habit)
	end
	return habits
end

local function extract_day_from_path(file_path)
	local filename = file_path:match("^.+/(.+)$")

	-- Convert the file_format to a pattern
	local pattern = M.config.day_format or "%Y-%m-%d.md"
	pattern = pattern:gsub("%%d", "(%%d%%d)")
	pattern = pattern:gsub("%%Y", "(%%d%%d%%d%%d)")
	pattern = pattern:gsub("%%m", "(%%d%%d)")
	pattern = pattern:gsub("%%", "%%") -- Escape any remaining % characters
	-- Match the pattern and extract the date components
	local year, month, day = filename:match(pattern)

	if year and day and month then
		return string.format("%s-%s-%s", year, month, day)
	else
		return nil
	end
end
local function get_boolen_form_files(files, keys, nilasfalse)
	if nilasfalse == nil then
		nilasfalse = true
	end
	if not keys or #keys == 0 then
		return {}
	end
	local values = {}
	for _, key in pairs(keys) do
		values[key] = {}
	end
	for _, file in pairs(files) do
		local content = M.utils.read_file(file)
		if content and #content > 0 then
			local date = extract_day_from_path(file)
			local yaml = M.parse_yaml_front_matter(content)
			if yaml and date then
				for _, key in pairs(keys) do
					if yaml[key] ~= nil then
						if type(yaml[key]) == "boolean" then
							table.insert(values[key], { date = date, value = yaml[key] })
						elseif nilasfalse then
							table.insert(values[key], { date = date, value = false })
						end
					end
				end
			end
		end
	end
	return values
end

local function get_value_form_files(files, value_name, nilaszero)
	if nilaszero == nil then
		nilaszero = false
	end
	if not value_name or value_name == "" then
		return {}
	end
	local values = {}
	for _, file in pairs(files) do
		local content = M.utils.read_file(file)
		if content and #content > 0 then
			local date = extract_day_from_path(file)
			local yaml = M.parse_yaml_front_matter(content)
			if yaml and date then
				if yaml[value_name] ~= nil then
					if type(yaml[value_name]) == "number" then
						table.insert(values, { x = date, type = "exact", value = yaml[value_name] })
					elseif nilaszero then
						table.insert(values, { x = date, type = "empty", value = 0 })
					end
				end
			end
		end
	end
	return values
end

-- M Functions

function M.parse_yaml_front_matter(content)
	if lyaml_exists then
		local front_matter = content:match("^%-%-%-(.-)%-%-%-")
		if front_matter then
			return lyaml.load(front_matter)
		end
	else
		M.log_message(
			"journal.parser.M.parse_yaml_front_matter",
			"lyaml not available, skipping YAML front matter parsing."
		)
	end
	return nil
end

---Setting up Config baes on module Jourlan one
---@param opts any Configuration passed form journal module
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	if M.config.journals then
		journals_dir = M.utils.normalize_folder_path(vim.fn.expand(M.config.journals))
	else
		vim.notify("Path to journals is not set", vim.log.levels.WARN)
	end
end
function M.get_habits(start_date, end_date, habits)
	local files = get_days_files(start_date, end_date)
	local values = get_boolen_form_files(files, habits)
	local ha = get_habits_from_values(values)
	return ha
end

function M.get_values(start_date, end_date, value_name)
	local files = get_days_files(start_date, end_date)
	local values = get_value_form_files(files, value_name)
	return values
end

function M.test(start_date, end_date, value_name)
	local files = get_days_files(start_date, end_date)
	local values = get_value_form_files(files, value_name)
	return values
end

return M
