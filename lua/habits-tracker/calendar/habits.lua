-- Placeholder for habits.lua
local M = {}
M.config = {
	padding = { 1, 1 },
	gird = {
		enable = true,
		borders = {
			hor = "┈",
			ver = "┊",
			left_down = "└",
			right_down = "┘",
			left_up = "┌",
			right_up = "┐",
			left_cross = "├",
			right_cross = "┤",
			cross = "┼",
			top_cross = "┬",
			down_cross = "┴",
			xs_hor = "═",
			xs_left_cross = "╞",
			xs_right_cross = "╡",
			xs_cross = "╪",
		},
		enable_vertical_lines = true,
		enable_horizontal_lines = true,
	},
	days_label = true,
	title = "Habits Tracker",
	title_format = "",
}
M.utils = require("habits-tracker.utils")
local min_cell_width = 1
local x_label = ""

-- local functions
--
local function get_date_range(series)
	if not series then
		return nil
	end
	local max_date = os.date("%Y-%m-%d", os.time({ year = 1970, month = 1, day = 1 }))
	local min_date = os.date("%Y-%m-%d", os.time())
	for _, v in ipairs(series) do
		if v.data and #v.data > 0 then
			for _, d in ipairs(v.data) do
				if d < min_date then
					min_date = d
				end
				if d > max_date then
					max_date = d
				end
			end
		end
	end
	return { min = min_date, max = max_date }
end

local function get_left_padding()
	local p_rl = ""
	if M.config and M.config.padding then
		if #M.config.padding > 1 then
			p_rl = string.format("%" .. M.config.padding[2] .. "s", " ")
		else
			p_rl = string.format("%" .. M.config.padding[1] .. "s", " ")
		end
	end
	return p_rl
end

local function is_grid_active()
	return M.config and M.config.gird and M.config.gird.enable
end

local function get_line(label, days)
	local ver = ""
	if M.config and M.config.gird and M.config.gird.enable then
		ver = M.config.gird.borders.ver or ""
	end
	local p_rl = get_left_padding()
	return ver .. p_rl .. label .. p_rl .. ver .. table.concat(days, ver) .. ver
end

local function get_top_line(label_length, cell_length, no_days)
	local p_rl = M.utils.utf8len(get_left_padding())
	local top_line = " "
	local left_up = " "
	local right_up = " "
	local top_cross = " "
	if is_grid_active() then
		top_line = M.config.gird.borders.hor or " "
		left_up = M.config.gird.borders.left_up or " "
		right_up = M.config.gird.borders.right_up or " "
		top_cross = M.config.gird.borders.top_cross or " "
	end
	local cell_label = left_up .. string.rep(top_line, (2 * p_rl) + label_length)
	local cell_days = ""
	for _ = 1, no_days do
		cell_days = cell_days .. top_cross .. string.rep(top_line, 2 * p_rl + cell_length)
	end
	return cell_label .. cell_days .. right_up
end

local function get_middle_line(label_length, cell_length, no_days)
	local p_rl = get_left_padding()
	local hor = " "
	local left_cross = " "
	local right_cross = " "
	local cross = " "
	if is_grid_active() then
		hor = M.config.gird.borders.hor or " "
		left_cross = M.config.gird.borders.left_cross or " "
		right_cross = M.config.gird.borders.right_cross or " "
		cross = M.config.gird.borders.cross or " "
	end

	local cell_label = left_cross .. string.rep(hor, (2 * M.utils.utf8len(p_rl)) + label_length)
	local cell_days = ""
	for _ = 1, no_days do
		cell_days = cell_days .. cross .. string.rep(hor, 2 * M.utils.utf8len(p_rl) + cell_length)
	end
	return cell_label .. cell_days .. right_cross
end

local function get_middle_line_xs(label_length, cell_length, no_days)
	local p_rl = get_left_padding()
	local hor = " "
	local left_cross = " "
	local right_cross = " "
	local cross = " "
	if is_grid_active() then
		hor = M.config.gird.borders.xs_hor or " "
		left_cross = M.config.gird.borders.xs_left_cross or " "
		right_cross = M.config.gird.borders.xs_right_cross or " "
		cross = M.config.gird.borders.xs_cross or " "
	end

	local cell_label = left_cross .. string.rep(hor, (2 * M.utils.utf8len(p_rl)) + label_length)
	local cell_days = ""
	for _ = 1, no_days do
		cell_days = cell_days .. cross .. string.rep(hor, 2 * M.utils.utf8len(p_rl) + cell_length)
	end
	return cell_label .. cell_days .. right_cross
end
local function get_bottom_line(label_length, cell_length, no_days)
	local p_rl = get_left_padding()
	local hor = " "
	local left_down = " "
	local right_down = " "
	local down_cross = " "
	if is_grid_active() then
		hor = M.config.gird.borders.hor or " "
		left_down = M.config.gird.borders.left_down or " "
		right_down = M.config.gird.borders.right_down or " "
		down_cross = M.config.gird.borders.down_cross or " "
	end

	local cell_label = left_down .. string.rep(hor, (2 * M.utils.utf8len(p_rl)) + label_length)
	local cell_days = ""
	for _ = 1, no_days do
		cell_days = cell_days .. down_cross .. string.rep(hor, 2 * M.utils.utf8len(p_rl) + cell_length)
	end
	return cell_label .. cell_days .. right_down
end

local function get_series_label_line(label_length, days)
	local p_rl = get_left_padding()
	local ver = " "
	if is_grid_active() then
		ver = M.config.gird.borders.ver or " "
	end

	-- local cell_label = ver .. string.rep(" ", (2 * M.utils.utf8len(p_rl)) + label_length)
	local cell_label = ver .. p_rl .. M.utils.align_right(x_label, label_length) .. p_rl
	local cell_days = ""
	for _, d in ipairs(days) do
		cell_days = cell_days .. ver .. p_rl .. d .. p_rl
	end
	return cell_label .. cell_days .. ver
end

local function get_days(habit, dates)
	local days = {}
	local p_rl = get_left_padding()
	for _, d in ipairs(dates) do
		if habit.data and vim.tbl_contains(habit.data, d) then
			table.insert(days, p_rl .. M.utils.align_center(habit.symbol, min_cell_width) .. p_rl)
		else
			table.insert(days, p_rl .. M.utils.align_center(" ", min_cell_width) .. p_rl)
		end
	end
	return days
end

local function get_max_label_length(series)
	local max = 0
	for _, v in ipairs(series) do
		if v.label and M.utils.utf8len(v.label) > max then
			max = M.utils.utf8len(v.label)
		end
	end
	return math.max(max, M.utils.utf8len(x_label))
end

local function get_days_labels(dates)
	local days_labels = {}
	local same_year = true
	local same_month = true
	if not dates or #dates < 1 then
		return days_labels
	end
	local year = string.sub(dates[1], 1, 4)
	local month = string.sub(dates[1], 6, 7)
	for _, d in ipairs(dates) do
		if year ~= string.sub(d, 1, 4) then
			same_year = false
		end
		if month ~= string.sub(d, 6, 7) then
			same_month = false
		end
	end
	for _, d in ipairs(dates) do
		if same_year and same_month then
			table.insert(days_labels, string.sub(d, 9, 10))
			x_label = string.sub(d, 1, 4) .. "-" .. string.sub(d, 6, 7)
		elseif same_year then
			table.insert(days_labels, string.sub(d, 6, 7) .. "-" .. string.sub(d, 9, 10))
			x_label = string.sub(d, 1, 4)
		else
			x_label = ""
			table.insert(days_labels, d)
		end
	end
	return days_labels
end

local function get_max_days_label_length(days)
	local max = 0
	for _, d in ipairs(days) do
		if M.utils.utf8len(d) > max then
			max = M.utils.utf8len(d)
		end
	end
	return max
end

-- M functions

--- comment
--- @param series any { { label: string, data: table, style={} } }
--- @param date_range any
--- @return table
function M.get_lines(series, date_range)
	local lines = {}
	local data = {}
	local grid_active = is_grid_active()
	date_range = date_range or get_date_range(series)
	-- print(vim.inspect(date_range))
	if not series then
		return lines
	end
	if not date_range then
		return lines
	end
	local dates = M.utils.generate_dates_in_range(date_range.min, date_range.max)
	local days_labels = get_days_labels(dates)
	local max_label_length = get_max_label_length(series)
	if M.config.days_label then
		min_cell_width = get_max_days_label_length(days_labels)
	end
	for _, v in ipairs(series) do
		table.insert(data, { label = M.utils.align_right(v.label, max_label_length), days = get_days(v, dates) })
	end
	local num_of_days = #data
	for index, d in ipairs(data) do
		if index == 1 and grid_active then
			table.insert(lines, get_top_line(max_label_length, min_cell_width, #d.days))
		end
		table.insert(lines, get_line(d.label, d.days))
		if grid_active and num_of_days > index then
			table.insert(lines, get_middle_line(max_label_length, min_cell_width, #days_labels))
		end
	end
	if grid_active then
		table.insert(lines, get_middle_line_xs(max_label_length, min_cell_width, #days_labels))
		table.insert(lines, get_series_label_line(max_label_length, days_labels))
		table.insert(lines, get_bottom_line(max_label_length, min_cell_width, #days_labels))
	end
	return lines
end

function M.add_habit_to_buffer(lines)
	local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
	if M.utils.is_cursor_between_fences() then
		vim.api.nvim_buf_set_lines(0, row, row, true, lines)
	else
		table.insert(lines, 1, "```ts")
		table.insert(lines, "```")
		vim.api.nvim_buf_set_lines(0, row, row, true, lines)
	end
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts)
	M.config.padding = M.config.padding or { 0, 0 }
	M.config.gird = M.config.gird or { enable = false }
end

return M
