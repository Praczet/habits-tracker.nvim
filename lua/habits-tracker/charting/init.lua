-- Placeholder for init.lua
local M = {}
M.config = {
	line = {},
	bar = {},
}
M.line = require("habits-tracker.charting.line")
M.bar = require("habits-tracker.charting.bar")

M.setup = function(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	M.line.setup(M.config.line)
	M.bar.setup(M.config.bar)
	-- Configuration for the charting module
end

function M.render_bar_vertical(start_date, end_date, data, y_label, title)
	local chart_data = M.bar.get_chart_data(start_date, end_date, data, y_label, title)
	M.bar.vertical(chart_data)
end

function M.get_bar_lines(start_date, end_date, data, y_label, title, bar_type, max_rows)
	local chart_data = M.bar.get_chart_data(start_date, end_date, data, y_label, title, max_rows)
	if bar_type == "vertical" then
		return M.bar.vertical(chart_data, false)
	else
		return M.bar.horizontal(chart_data, false)
	end
end

function M.render_bar_horizontal(start_date, end_date, data, y_label, title)
	local chart_data = M.bar.get_chart_data(start_date, end_date, data, y_label, title)
	M.bar.horizontal(chart_data)
end

function M.render_bar(start_date, end_date, data, y_label, title, bar_type)
	if bar_type == "vertical" then
		M.render_bar_vertical(start_date, end_date, data, y_label, title)
	elseif bar_type == "horizontal" then
		M.render_bar_horizontal(start_date, end_date, data, y_label, title)
	end
end

function M.test(start_date, end_date, data, y_label, title)
	--- Testing barchar
	-- local chart_data = {
	-- 	y_label = "Weight",
	-- 	x_label = "",
	-- 	max_rows = 10,
	-- 	add_aprox = true,
	-- 	x_min = start_date,
	-- 	x_max = end_date,
	-- 	max_height_value = 0.8,
	-- 	title = string.format("Weight (kg) %s - %s", start_date, end_date),
	-- 	data = data,
	-- }
	M.render_bar_vertical(start_date, end_date, data, y_label, title)
	M.render_bar_horizontal(start_date, end_date, data, y_label, title)
end
return M
