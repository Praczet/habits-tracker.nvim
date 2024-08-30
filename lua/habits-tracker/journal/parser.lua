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
-- Function to parse a date string in the format "YYYY-MM-DD"
local function parse_date(date_str)
	local year, month, day = date_str:match("(%d+)-(%d+)-(%d+)")
	return os.time({ year = year, month = month, day = day })
end

-- Function to calculate the start of the week based on the configured first day
local function get_start_of_week(date, start_day)
	local date_table = os.date("*t", date)
	local day_of_week = date_table.wday - 1 -- os.date returns 1 (Sunday) to 7 (Saturday)
	local diff = (day_of_week - start_day) % 7
	return os.time({
		year = date_table.year,
		month = date_table.month,
		day = date_table.day - diff,
		hour = 0,
		min = 0,
		sec = 0,
	})
	-- print("date", date, "start_day", start_day)
	-- local day_of_week = date:weekday() -- Returns 1 (Sunday) to 7 (Saturday)
	-- local adjusted_day_of_week = (day_of_week - 1) % 7 -- Normalize to 0 (Sunday) to 6 (Saturday)
	-- local diff = (adjusted_day_of_week - start_day) % 7
	-- return date - diff * 24 * 60 * 60 -- Subtract the difference in days to get the start of the week
end

local function get_week_label(date, start_day)
	local start_of_week = get_start_of_week(date, start_day)
	return os.date("%Y-W%V", start_of_week) -- Week label in the format "2024-W01"
end

local function get_month_label(date)
	return os.date("%Y-%m", date)
end

local function get_quarter_label(date)
	local month = tonumber(os.date("%m", date))
	local quarter = math.ceil(month / 3)
	return string.format("Q%d", quarter)
end

local function get_year_label(date)
	return os.date("%Y", date)
end

-- M Functions

-- Function to aggregate values based on the interval and configuration
function M.aggregate_values_by_interval(data, interval, round, start_day)
	local aggregated_data = {}
	local current_label = nil
	local sum, count, is_approx = 0, 0, false

	for i, entry in ipairs(data) do
		local date = parse_date(entry.x)

		-- Determine the current label based on the interval
		local label
		if interval == "day" then
			label = os.date("%Y-%m-%d", date)
		elseif interval == "week" then
			label = get_week_label(date, start_day)
		elseif interval == "month" then
			label = get_month_label(date)
		elseif interval == "quarter" then
			label = get_quarter_label(date)
		elseif interval == "year" then
			label = get_year_label(date)
		end

		-- Aggregate data if it's the same label, otherwise store and reset
		if current_label == label then
			sum = sum + entry.value
			count = count + 1
			if entry.type ~= "exact" then
				is_approx = true
			end
		else
			if current_label then
				local avg_value = sum / count
				if round ~= nil then
					avg_value = tonumber(string.format("%." .. round .. "f", avg_value)) or math.floor(avg_value)
				else
					avg_value = math.floor(avg_value)
				end

				table.insert(aggregated_data, {
					x = current_label,
					value = avg_value,
					type = is_approx and "approx" or "exact",
				})
			end

			-- Reset for the next label
			current_label = label
			sum, count, is_approx = entry.value, 1, entry.type ~= "exact"
		end
	end

	-- Store the last aggregated value
	if current_label then
		local avg_value = sum / count
		if round ~= nil then
			avg_value = tonumber(string.format("%." .. round .. "f", avg_value))
		else
			avg_value = math.floor(avg_value)
		end

		table.insert(aggregated_data, {
			x = current_label,
			value = avg_value,
			type = is_approx and "approx" or "exact",
		})
	end

	return aggregated_data
end
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
