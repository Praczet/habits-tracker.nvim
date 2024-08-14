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
return M
