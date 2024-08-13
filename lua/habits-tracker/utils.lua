local M = {}
M.config = {
	first_dow = "su", -- Default first day of the week is Monday
}
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

function M.generate_dates_in_range(start_date, end_date)
	local dates = {}
	local current_date = os.time({
		year = start_date:sub(1, 4),
		month = start_date:sub(6, 7),
		day = start_date:sub(9, 10),
	})
	local end_date_time = os.time({
		year = end_date:sub(1, 4),
		month = end_date:sub(6, 7),
		day = end_date:sub(9, 10),
	})

	while current_date <= end_date_time do
		table.insert(dates, os.date("%Y-%m-%d", current_date))
		current_date = current_date + 86400 -- add one day in seconds
	end

	return dates
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
	print(
		"text: " .. text,
		", max_length: " .. max_length .. ", #text: " .. #text .. ", utf8len(text): " .. M.utf8len(text)
	)
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

return M
