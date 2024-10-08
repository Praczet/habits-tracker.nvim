local M = {}
M.config = {
	first_dow = "su", -- Default first day of the week is Monday
}
M.debug = true
local day_map = {
	su = 0, -- Sunday
	mo = 1, -- Monday
	tu = 2, -- Tuesday
	we = 3, -- Wednesday
	th = 4, -- Thursday
	fr = 5, -- Friday
	sa = 6, -- Saturday
}

function M.get_first_day_of_week()
	return day_map[M.config.first_dow:sub(1, 2):lower()]
end
--
-- Function to parse "YYYY-WXX" format and return the start and end dates of the week
function M.get_week_range(week_string, start_day, as_string)
	local year, week_number = week_string:match("(%d+)-W(%d+)")
	year = tonumber(year)
	week_number = tonumber(week_number)

	if year == nil or week_number == nil then
		return nil
	end

	-- Get January 1st of the year
	local jan1 = os.time({ year = year, month = 1, day = 1 })

	-- Find the first start_day of the year
	local jan1_wday = tonumber(os.date("%w", jan1)) -- 0 = Sunday, 6 = Saturday
	local start_day_wday = day_map[start_day]

	local days_to_first_start_day = (start_day_wday - jan1_wday + 7) % 7
	local first_start_day = jan1 + days_to_first_start_day * 24 * 60 * 60

	-- Calculate the start of the given week
	local start_of_week = first_start_day + (week_number - 1) * 7 * 24 * 60 * 60

	-- Calculate the end of the week (6 days after the start)
	local end_of_week = start_of_week + 6 * 24 * 60 * 60

	-- Convert to "YYYY-MM-DD" format if needed
	local from_date = as_string and os.date("%Y-%m-%d", start_of_week) or start_of_week
	local to_date = as_string and os.date("%Y-%m-%d", end_of_week) or end_of_week

	return {
		from = from_date,
		startDay = start_day,
		to = to_date,
	}
end

-- Function to parse "YYYY-QX" format and return the start and end dates of the quarter
function M.get_quarter_range(quarter_string, as_string)
	local year, quarter = quarter_string:match("(%d+)-Q(%d+)")
	year = tonumber(year)
	quarter = tonumber(quarter)
	if year == nil or quarter == nil then
		return nil
	end

	-- Define the start and end months for each quarter
	local quarter_start_months = { 1, 4, 7, 10 }
	local quarter_end_months = { 3, 6, 9, 12 }

	local start_month = quarter_start_months[quarter]
	local end_month = quarter_end_months[quarter]

	-- Get the start and end dates of the quarter
	local start_of_quarter = os.time({ year = year, month = start_month, day = 1, hour = 0, min = 0, sec = 0 })
	local end_of_quarter = os.time({ year = year, month = end_month + 1, day = 1, hour = 0, min = 0, sec = 0 }) - 1

	-- Convert to "YYYY-MM-DD" format if needed
	local from_date = as_string and os.date("%Y-%m-%d", start_of_quarter) or start_of_quarter
	local to_date = as_string and os.date("%Y-%m-%d", end_of_quarter) or end_of_quarter

	return {
		from = from_date,
		to = to_date,
		quarter = quarter_string,
	}
end

function M.get_current_week()
	-- Get today's date information
	local today = os.time()
	local today_weekday = tonumber(os.date("%w", today))

	-- Determine the first day of the week based on the config
	local first_dow = day_map[M.config.first_dow:sub(1, 2):lower()] -- Extract first two characters and normalize

	-- Calculate the start and end of the week
	local diff_to_start = today_weekday - first_dow
	if diff_to_start < 0 then
		diff_to_start = diff_to_start + 7
	end
	local start_of_week = os.time({
		year = tostring(os.date("%Y", today)),
		month = tostring(os.date("%m", today)),
		day = tostring(os.date("%d", today)),
	}) - (diff_to_start * 24 * 60 * 60)

	local end_of_week = start_of_week + (6 * 24 * 60 * 60) -- 6 days after the start

	-- Format the dates to YYYY-MM-DD
	local min_day = os.date("%Y-%m-%d", start_of_week)
	local max_day = os.date("%Y-%m-%d", end_of_week)

	return min_day, max_day
end

function M.log_message(module_name, message)
	if not M.debug then
		return
	end
	local log_file = vim.fn.expand("~/.config/nvim/nvim-markdown-links.log")
	local log_entry = os.date("%Y-%m-%d %H:%M:%S") .. "\t" .. module_name .. "\t" .. message .. "\n"
	local file = io.open(log_file, "a")
	if file then
		file:write(log_entry)
		file:close()
	end
end

function M.read_file(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return nil
	end
	local content = file:read("*all")
	file:close()
	return content
end

function M.generate_dates_in_range(start_date, end_date)
	local dates = {}
	local current_date = M.get_os_time(start_date)
	local end_date_time = M.get_os_time(end_date)
	while current_date <= end_date_time do
		table.insert(dates, os.date("%Y-%m-%d", current_date))
		current_date = current_date + 86400 -- add one day in seconds
	end

	return dates
end

function M.get_os_time(date)
	if not date then
		return nil
	end
	return os.time({
		year = string.sub(date, 1, 4),
		month = string.sub(date, 6, 7),
		day = string.sub(date, 9, 10),
	})
end

function M.file_exists(path)
	local file = io.open(path, "r")
	if file then
		file:close()
		return true
	else
		return false
	end
end

function M.utf8len(str)
	local len = 0
	for _ in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
		len = len + 1
	end
	return len
end

function M.align_right(text, max_length)
	local text_length = M.utf8len(text)
	if text_length < max_length then
		return string.rep(" ", max_length - text_length) .. text
	else
		return text
	end
	-- return string.format("%" .. max_length .. "s", text)
end

function M.align_left(text, max_length)
	local text_length = M.utf8len(text)
	if text_length < max_length then
		return text .. string.rep(" ", max_length - text_length)
	else
		return text
	end
	-- return string.format("%-" .. max_length .. "s", text)
end

function M.align_center(text, width)
	local text_length = M.utf8len(text)
	if text_length >= width then
		return text
	end
	local padding = (width - text_length) / 2
	local left_padding = math.floor(padding)
	local right_padding = math.ceil(padding)
	return string.rep(" ", left_padding) .. text .. string.rep(" ", right_padding)
end

function M.is_cursor_between_fences()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_line = cursor_pos[1]
	local total_lines = vim.api.nvim_buf_line_count(0)
	local inside_fence = false
	local start_fence_line = nil
	for line_num = 1, total_lines do
		local line_content = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
		if line_content:match("^%s*```") then
			if inside_fence then
				if cursor_line > start_fence_line and cursor_line < line_num then
					return true
				end
				inside_fence = false
				start_fence_line = nil
			else
				inside_fence = true
				start_fence_line = line_num
			end
		end
	end
	return false
end

function M.normalize_folder_path(folder_path)
	return folder_path:gsub("/$", "")
end

-- Utility function to parse a string into a Lua table if it is a list
function M.parse_list(value)
	value = value:match("^%s*(.-)%s*$")
	-- Check if the value is a list (starts with "[" and ends with "]")
	if value:match("^%[.*%]$") then
		-- Remove the square brackets and split the contents by commas
		local list_content = value:sub(2, -2) -- Remove the square brackets
		local list = {}
		for item in list_content:gmatch("[^,%s]+") do
			-- Trim spaces and add to the list
			table.insert(list, item:match("^%s*(.-)%s*$"))
		end
		return list
	else
		return value -- Return the original value if it's not a list
	end
end

function M.parse_curly_content(content)
	local parameters = {}
	local param = ""
	local in_quotes = false
	local quote_char = nil

	-- Handle cases where only {Habits} or {Track} is present without additional parameters
	if content:match("^%s*(Habits)%s*$") then
		parameters["Habits"] = {}
		return parameters
	elseif content:match("^%s*(Track)%s*$") then
		parameters["Track"] = ""
		return parameters
	end

	-- Regular parsing logic for key-value pairs
	for i = 1, #content do
		local char = content:sub(i, i)

		if char == '"' or char == "'" then
			if in_quotes and quote_char == char then
				in_quotes = false
				quote_char = nil
			elseif not in_quotes then
				in_quotes = true
				quote_char = char
			end
		end

		if char == ";" and not in_quotes then
			local key, value = param:match("^%s*(.-)%s*:%s*(.-)%s*$")
			if key and value then
				-- Special handling for the "Habits" key
				if key == "Habits" then
					parameters[key] = M.parse_list(value)
				else
					parameters[key] = value
				end
			end
			param = ""
		else
			param = param .. char
		end
	end

	-- Process the last parameter
	if param ~= "" then
		local key, value = param:match("^%s*(.-)%s*:%s*(.-)%s*$")
		if key and value then
			-- Special handling for the "Habits" key
			if key == "Habits" then
				parameters[key] = M.parse_list(value)
			else
				parameters[key] = value
			end
		end
	end

	return parameters
end

function M.find_fenced_blocks(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local result = {}

	local i = 1
	while i <= #lines do
		local line = lines[i]
		local start_match = line:match("^```" .. (M.config.fenced_lang or "ts") .. "%s*{(Track:.-)}")
		local habits_match = line:match("^```" .. (M.config.fenced_lang or "ts") .. "%s*{(Habits:.-)}")
		local simple_habits_match = line:match("^```" .. (M.config.fenced_lang or "ts") .. "%s*{(Habits)}$")
		local simple_track_match = line:match("^```" .. (M.config.fenced_lang or "ts") .. "%s*{(Track)}$")

		if start_match or habits_match or simple_habits_match or simple_track_match then
			local block_type = start_match and "Track" or (habits_match or simple_habits_match) and "Habits" or "Track"
			local param_string = start_match or habits_match or simple_habits_match or simple_track_match
			local params = M.parse_curly_content(param_string)
			local start_line = i

			-- Find the end of the fenced block
			while i <= #lines do
				if lines[i]:match("^```") and i > start_line then
					local end_line = i
					table.insert(result, {
						parameters = params,
						start_line = start_line,
						end_line = end_line,
						block_type = block_type,
						param_string = param_string,
					})
					break
				end
				i = i + 1
			end
		end

		i = i + 1
	end

	return result
end

function M.setup(config)
	M.config = vim.tbl_deep_extend("force", M.config, config or {})
	M.debug = M.config.debug
end
return M
