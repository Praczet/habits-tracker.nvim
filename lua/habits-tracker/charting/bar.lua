-- Placeholder for bar.lua
local M = {}
M.config = {
	show_legend = true,
	show_oxy = true,
	max_rows = 6,
	oxy = {
		cross = "┼",
		ver = "┊",
		hor = "┈",
	},
}

M.utils = require("habits-tracker.utils")

local ver = ""
local hor = ""
local cross = ""
local label_len = 6
local x_label = ""
local x_label_value_len = 3
local padding = 1

local function setup_ox()
	if M.config and M.config.show_oxy and M.config.oxy then
		ver = M.config.oxy.ver or ver
		hor = M.config.oxy.hor or hor
		cross = M.config.oxy.cross or cross
	end
end
-- Function to interpolate and calculate bar heights
local function interpolate_approx(data, max_rows, max_height_value, x_min, x_max)
	-- Ensure max_height_value is between 0 and 1
	max_height_value = math.max(0, math.min(max_height_value, 1))

	-- Find the actual min and max dates in the data
	local actual_min_x = tostring(os.date("%Y-%m-%d"))
	local actual_max_x = tostring(os.date("%Y-%m-%d"))
	if #data > 0 then
		actual_min_x = data[1].x
		actual_max_x = data[#data].x
	end

	-- Use provided x_min and x_max if available, otherwise default to actual data range
	local x_min_time = x_min
			and os.time({
				year = string.sub(x_min, 1, 4),
				month = string.sub(x_min, 6, 7),
				day = string.sub(x_min, 9, 10),
			})
		or os.time({
			year = string.sub(actual_min_x, 1, 4),
			month = string.sub(actual_min_x, 6, 7),
			day = string.sub(actual_min_x, 9, 10),
		})

	local x_max_time = x_max
			and os.time({
				year = string.sub(x_max, 1, 4),
				month = string.sub(x_max, 6, 7),
				day = string.sub(x_max, 9, 10),
			})
		or os.time({
			year = string.sub(actual_max_x, 1, 4),
			month = string.sub(actual_max_x, 6, 7),
			day = string.sub(actual_max_x, 9, 10),
		})

	-- Find the max value in the dataset for scaling
	local max_value = 0
	for _, point in ipairs(data) do
		if point.value > max_value then
			max_value = point.value
		end
	end

	-- Adjust scaling based on max_height_value
	local scaling_factor = max_height_value * max_rows

	-- Create a filled dataset covering the entire x_min to x_max range
	local filled_data = {}

	-- Iterate through the range from x_min to x_max
	for t = x_min_time, x_max_time, 24 * 60 * 60 do
		local date_str = os.date("%Y-%m-%d", t)

		if
			t
				< os.time({
					year = string.sub(actual_min_x, 1, 4),
					month = string.sub(actual_min_x, 6, 7),
					day = string.sub(actual_min_x, 9, 10),
				})
			or t
				> os.time({
					year = string.sub(actual_max_x, 1, 4),
					month = string.sub(actual_max_x, 6, 7),
					day = string.sub(actual_max_x, 9, 10),
				})
		then
			-- Outside the actual data range, add empty data
			table.insert(filled_data, { type = "empty", value = 0, x = date_str })
		else
			-- Within the actual data range, check if we have an exact or approximate value
			local found = false
			for i = 1, #data - 1 do
				local p1 = data[i]
				local p2 = data[i + 1]

				-- Add exact data points
				if p1.x == date_str then
					table.insert(filled_data, p1)
					found = true
					break
				end

				-- Add interpolated data points
				local p1_time = os.time({
					year = string.sub(p1.x, 1, 4),
					month = string.sub(p1.x, 6, 7),
					day = string.sub(p1.x, 9, 10),
				})
				local p2_time = os.time({
					year = string.sub(p2.x, 1, 4),
					month = string.sub(p2.x, 6, 7),
					day = string.sub(p2.x, 9, 10),
				})

				if t > p1_time and t < p2_time then
					local days_diff = (p2_time - p1_time) / (24 * 60 * 60)
					local days_elapsed = (t - p1_time) / (24 * 60 * 60)
					local interpolated_value = p1.value + (days_elapsed / days_diff) * (p2.value - p1.value)
					table.insert(filled_data, { type = "aprox", value = interpolated_value, x = date_str })
					found = true
					break
				end
			end

			if not found and #data > 0 and data[#data].x == date_str then
				table.insert(filled_data, data[#data])
			end
		end
	end

	-- Calculate the heights of bars
	local bars = {}
	for _, point in ipairs(filled_data) do
		local height = math.floor((point.value / max_value) * scaling_factor)
		table.insert(bars, { height = height, x = point.x, type = point.type, value = point.value })
	end

	return bars
end

local function set_x_label(bars)
	if #bars == 0 then
		return
	end
	local same_year = true
	local same_month = true
	local year = string.sub(bars[1].x, 1, 4)
	local month = string.sub(bars[1].x, 6, 7)
	for _, d in ipairs(bars) do
		if year ~= string.sub(d.x, 1, 4) then
			same_year = false
		end
		if month ~= string.sub(d.x, 6, 7) then
			same_month = false
		end
	end
	for _, d in ipairs(bars) do
		if same_year and same_month then
			x_label = string.sub(d.x, 1, 4) .. "-" .. string.sub(d.x, 6, 7)
			x_label_value_len = 3 + 2 * padding
		elseif same_year then
			x_label = string.sub(d.x, 1, 4)
			x_label_value_len = 5 + 2 * padding
		else
			x_label = ""
			x_label_value_len = 11 + 2 * padding
		end
	end
	label_len = math.max(M.utils.utf8len(x_label), label_len)
end

local function get_x_value_label(value)
	if x_label_value_len == (3 + 2 * padding) then
		return string.sub(value, 9, 10)
	end
	if x_label_value_len == (5 + 2 * padding) then
		return string.sub(value, 6, 10)
	else
		return value
	end
end

local function get_pad()
	return string.rep(" ", padding)
end

---
function M.vertical_get_lines(bars, max_rows, show_legend, max_height_value, title)
	local display = {}
	local lines = {}
	set_x_label(bars)

	-- Initialize display table with empty strings
	for i = 1, max_rows do
		display[i] = ""
	end

	-- Find the max and min values from the non-empty bars
	local max_value = -math.huge
	local min_value = math.huge
	for _, bar in ipairs(bars) do
		if bar.value > max_value and bar.type ~= "empty" then
			max_value = bar.value
		end
		if bar.value < min_value and bar.type ~= "empty" then
			min_value = bar.value
		end
	end

	-- Calculate the positions for the min and max values, considering max_height_value
	local scaled_max_rows = math.floor(max_rows * max_height_value)
	local max_position = max_rows - math.floor((max_value / max_value) * (scaled_max_rows - 1))
	local min_position = max_rows - math.floor((min_value / max_value) * (scaled_max_rows - 1))
	local pad = get_pad()

	-- Fill the display table by transposing the bar chart
	for _, bar in ipairs(bars) do
		for i = 1, max_rows do
			if i <= max_rows - bar.height then
				display[i] = display[i] .. M.utils.align_center(pad .. " " .. pad, x_label_value_len) -- Empty space for bars that don't reach this row
			else
				local ch_bar = M.utils.align_center(pad .. "█" .. pad, x_label_value_len)
				if bar.type == "aprox" then
					ch_bar = M.utils.align_center(pad .. "░" .. pad, x_label_value_len)
				end
				display[i] = display[i] .. ch_bar -- Bar segment
			end
		end
	end

	-- Print the transposed bar chart with min and max legend values on the left side
	for i = 1, max_rows do
		local legend = ""
		if show_legend then
			if i == max_position then
				legend = M.utils.align_right(string.format("%3.1f ", max_value), label_len) -- Print max value
			elseif i == min_position then
				legend = M.utils.align_right(string.format("%3.1f ", min_value), label_len) -- Print max value
			else
				legend = string.rep(" ", label_len) -- Keep space for alignment
			end
		end
		table.insert(lines, legend .. ver .. display[i])
	end

	if M.config and M.config.show_oxy then
		table.insert(lines, string.rep(hor, label_len) .. cross .. string.rep(hor, #bars * x_label_value_len))
	end
	local labels = M.utils.align_right(x_label, label_len) .. ver -- Space for the legend area
	for _, bar in ipairs(bars) do
		labels = labels .. M.utils.align_center(get_x_value_label(bar.x), x_label_value_len) -- Extract the day portion of the date
	end
	table.insert(lines, labels)
	if title and #title > 0 then
		local title_len = M.utils.utf8len(title)
		if #lines > 0 and M.utils.utf8len(lines[1]) > title_len then
			title_len = M.utils.utf8len(lines[1])
		end
		table.insert(lines, string.rep(hor, title_len))
		table.insert(lines, M.utils.align_center(title, title_len))
	end
	return lines
end

function M.horizontal_get_lines(bars, max_rows, show_legend, title)
	set_x_label(bars)
	local lines = {}
	local num_of_bars = #bars
	for bar_num, bar in ipairs(bars) do
		local ch_bar = "█"
		if bar.type == "aprox" then
			ch_bar = "░"
		end

		local line = get_x_value_label(bar.x)
			.. ver
			.. M.utils.align_left(string.rep(ch_bar, bar.height), max_rows)
			.. M.utils.align_right(string.format("%3.1f", bar.value), label_len)
		table.insert(lines, line)
		if num_of_bars > bar_num then
			local xl_no = M.utils.utf8len(get_x_value_label(bar.x))
			line = string.rep(hor, xl_no) .. cross .. string.rep(hor, max_rows) .. string.rep(hor, label_len)
			table.insert(lines, line)
		end
	end
	if title and #title > 0 then
		local title_len = M.utils.utf8len(title)
		if #lines > 0 and M.utils.utf8len(lines[1]) > title_len then
			title_len = M.utils.utf8len(lines[1])
		end
		table.insert(lines, string.rep(hor, title_len))
		table.insert(lines, M.utils.align_center(title, title_len))
	end
	return lines
end
function M.add_lines_to_buffer(lines)
	local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
	if M.utils.is_cursor_between_fences() then
		vim.api.nvim_buf_set_lines(0, row, row, true, lines)
	else
		table.insert(lines, 1, "```ts")
		table.insert(lines, "```")
		vim.api.nvim_buf_set_lines(0, row, row, true, lines)
	end
end
function M.vertical(chart_data, add_to_buffer)
	-- checking if it should be added to buffer
	if add_to_buffer == nil then
		add_to_buffer = true
	end
	-- sorting data by x (day)
	table.sort(chart_data.data, function(a, b)
		return a.x < b.x
	end)
	local bars = interpolate_approx(
		chart_data.data,
		chart_data.max_rows,
		chart_data.max_height_value,
		chart_data.x_min,
		chart_data.x_max
	)
	local lines = M.vertical_get_lines(
		bars,
		chart_data.max_rows,
		M.config.show_legend,
		chart_data.max_height_value,
		chart_data.title
	)
	if add_to_buffer then
		M.add_lines_to_buffer(lines)
	else
		return lines
	end
end

function M.horizontal(chart_data, add_to_buffer)
	-- checking if it should be added to buffer
	if add_to_buffer == nil then
		add_to_buffer = true
	end
	-- sorting data by x (day)
	table.sort(chart_data.data, function(a, b)
		return a.x < b.x
	end)
	local bars = interpolate_approx(
		chart_data.data,
		chart_data.max_rows,
		chart_data.max_height_value,
		chart_data.x_min,
		chart_data.x_max
	)
	local lines = {}
	lines = M.horizontal_get_lines(bars, chart_data.max_rows, M.config.show_legend, chart_data.title)
	if add_to_buffer then
		M.add_lines_to_buffer(lines)
	else
		return lines
	end
end

function M.get_chart_data(start_date, end_date, data, y_label, title, max_rows)
	return {
		y_label = y_label,
		x_label = "",
		max_rows = max_rows or M.config.max_rows or 10,
		add_aprox = true,
		x_min = start_date,
		x_max = end_date,
		max_height_value = 0.8,
		title = string.format((title or y_label .. ": %s - %s"), start_date, end_date),
		data = data,
	}
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	setup_ox()
	x_label_value_len = 2 * padding + 1
end

return M
