local M = {}

M.config = {
	journals = "~/Notes/Journal/daily",
	day_format = "%Y-%m-%d.md",
	tmpl_daily = "~/Notes/templates/Daily.md",
	first_dow = "su", -- Default first day of the week is Monday
	habits = {
		{
			label = "French",
			style = { fg = "red" },
			symbol = "■",
		},
		{
			label = "Reading",
			style = { fg = "red" },
			symbol = "◆",
		},
		{
			label = "Sport",
			style = { fg = "red" },
			symbol = "▼",
		},
	},
	charting = {
		line = {},
		bar = {
			show_legend = true,
			show_oxy = true,
			max_rows = 10,
			oxy = {
				cross = "┼",
				ver = "┊",
				hor = "┈",
			},
		},
	},
	calendar = {
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
	},
}

-- Load modules
M.charting = require("habits-tracker.charting")
M.calendar = require("habits-tracker.calendar")
M.journal = require("habits-tracker.journal")
M.utils = require("habits-tracker.utils")

local function parse_params_journal(args)
	local date = os.date("%Y-%m-%d") -- Default to the current date
	local replacements = {}
	if not args then
		return date, replacements
	end

	for _, arg in ipairs(args) do
		local key, value = arg:match("^(%w+)=([%w%p]+)$")
		if arg:match("^%d%d%d%d%-%d%d%-%d%d$") then
			date = arg -- If a valid date is found, use it
		elseif key and value then
			replacements[key:lower()] = value
		else
			vim.notify("Invalid argument: " .. arg, vim.log.levels.ERROR)
		end
	end

	return date, replacements
end
local function parse_params_date(date)
	local start_date, end_date
	if date == "week" then
		start_date, end_date = M.utils.get_current_week()
	elseif date == "month" then
		start_date, end_date = M.utils.get_current_week()
	elseif date == "year" then
		start_date, end_date = M.utils.get_current_week()
	elseif date and type(date) == "string" then
		local d_temp = vim.split(tostring(date), ":", { trimempty = true })
		if #d_temp ~= 2 then
			start_date, end_date = M.utils.get_current_week()
		else
			start_date = d_temp[1]
			end_date = d_temp[2]
		end
	else
		start_date, end_date = M.utils.get_current_week()
	end
	return start_date, end_date
end

local function parse_args_bar(args)
	local params = {
		date = "week", -- Default value for date
		title = nil, -- Default value for habits (nil if omitted)
		value = nil,
	}

	-- Process value
	if args and #args > 0 then
		params.value = args[1]
	end
	-- Process date
	if args and #args > 1 then
		-- Check if it's a word like 'week', 'month', 'year', or a range
		if args[2]:match("^%d%d%d%d%-%d%d%-%d%d:%d%d%d%d%-%d%d%-%d%d$") then
			params.date = args[2] -- It's a range
		elseif args[2] == "week" or args[2] == "month" or args[2] == "year" then
			params.date = args[2] -- It's a word
		else
			vim.api.nvim_err_writeln("Invalid date format. Use 'week', 'month', 'year', or 'YYYY-MM-DD:YYYY-MM-DD'.")
			return nil
		end
	end

	if args and #args > 2 then
		params.title = args[3]:gsub('"', "")
		for i = 4, #args, 1 do
			params.title = params.title .. " " .. args[i]:gsub('"', "")
		end
	end

	return params
end
local function parse_args_habits(args)
	local params = {
		date = "week", -- Default value for date
		habits = nil, -- Default value for habits (nil if omitted)
	}

	-- Process date
	if args and #args > 0 then
		-- Check if it's a word like 'week', 'month', 'year', or a range
		if args[1]:match("^%d%d%d%d%-%d%d%-%d%d:%d%d%d%d%-%d%d%-%d%d$") then
			params.date = args[1] -- It's a range
		elseif args[1] == "week" or args[1] == "month" or args[1] == "year" then
			params.date = args[1] -- It's a word
		else
			vim.api.nvim_err_writeln("Invalid date format. Use 'week', 'month', 'year', or 'YYYY-MM-DD:YYYY-MM-DD'.")
			return nil
		end
	end

	-- Process habits
	if args and #args > 1 then
		params.habits = vim.split(args[2], ",", { trimempty = true })
	end

	return params
end
local function habits_command(args)
	-- Parse and validate arguments
	local params = parse_args_habits(args)
	if not params then
		return
	end
	local start_date, end_date = parse_params_date(params.date)

	-- Example logic
	if not params.habits or #params.habits == 0 then
		if M.config and M.config.habits then
			params.habits = {}
			for _, habit in pairs(M.config.habits) do
				table.insert(params.habits, habit.label)
			end
		end
	end
	if not params.habits or #params.habits == 0 then
		vim.notify("Habits list is empty, check your configuration", vim.log.levels.WARN)
		return
	end
	local habits = M.journal.get_habits(start_date, end_date, params.habits)
	M.calendar.render_habits(habits, start_date, end_date)
end

local function bar_command(args, bar_type)
	-- Parse and validate arguments
	local params = parse_args_bar(args)
	if not params then
		return
	end
	local start_date, end_date = parse_params_date(params.date)

	-- Example logic
	if not params.value or params.value == "" then
		vim.notify("Value to load is empty", vim.log.levels.WARN)
		return
	end
	if not params.tilte or params.tilte == "" then
		params.tilte = params.value .. ": %s - %s"
	end
	local data = M.journal.get_values(start_date, end_date, params.value)
	M.charting.render_bar(start_date, end_date, data, params.value, params.title, bar_type)
end
-- Command implementation
local function journal_command(opts)
	local date, replacements = parse_params_journal(opts)
	M.journal.create_journal(date, replacements)
end

local function add_user_command()
	vim.api.nvim_create_user_command("Habits", function(opts)
		habits_command(opts.fargs)
	end, {
		nargs = "*", -- Allow zero or more arguments
		-- complete = function(arglead, cmdline, cursorpos)
		--     -- Custom completion logic (if needed)
		--     return {"week", "month", "year"}
		-- end,
	})

	vim.api.nvim_create_user_command("Track", function(opts)
		bar_command(opts.fargs, "vertical")
	end, { nargs = "*" })

	vim.api.nvim_create_user_command("Journal", function(opts)
		journal_command(opts.fargs)
	end, { nargs = "*" })

	vim.api.nvim_create_user_command("TrackBarHorizontal", function(opts)
		bar_command(opts.fargs, "horizontal")
	end, { nargs = "*" })

	vim.api.nvim_create_user_command("TrackBarVertical", function(opts)
		bar_command(opts.fargs, "vertical")
	end, { nargs = "*" })
end

---Gets lines for bar chart
---@param value_name string Value to read from YAML fronter
---@param opts {} Options:
---       - **bar_type** string
---       - **title** string Chart title (optional)
---       - **start_date** string|osdate Start Date (optional) in format YYYY-MM-DD
---       - **end_date** string|osdate End Date (optional) in format YYYY-MM-DD
---table string[] Lines to be rendered
function M.get_bar_lines(value_name, opts)
	if not opts then
		opts = {}
	end
	local lines = {}
	if not value_name or value_name == "" then
		vim.notify("Parameters values is empty", vim.log.levels.WARN)
		return {}
	end
	if not opts.bar_type or opts.bar_type == "" then
		opts.bar_type = "vertical"
	end
	if opts.start_date == nil then
		opts.start_date, opts.end_date = M.utils.get_current_week()
	end
	if opts.title == nil or opts.title == "" then
		opts.title = value_name .. ": %s - %s"
	end
	if opts.max_rows == nil then
		opts.max_rows = 6
	end
	local data = M.journal.get_values(opts.start_date, opts.end_date, value_name)
	lines = M.charting.get_bar_lines(
		opts.start_date,
		opts.end_date,
		data,
		value_name,
		opts.title,
		opts.bar_type,
		opts.max_rows
	)
	return lines
end
-- Any initialization code
function M.setup(opts)
	-- Set up each module with user-provided options or defaults
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", M.config, opts)
	M.charting.setup(M.config.charting)
	M.utils.setup(M.config)
	M.calendar.setup(M.config.calendar)
	M.journal.setup(M.config)
	add_user_command()
end

function M.test()
	vim.notify("Test triggered")
	-- M.charting.test()
	-- M.calendar.test()
	-- M.journal.test(M.utils.get_current_week())
	local start_date = "2024-05-06"
	local end_date = "2024-05-23"
	local y_label = "Weight"
	local title = "Weight (kg): %s - %s"
	local data = M.journal.test(start_date, end_date, y_label)
	M.charting.test(start_date, end_date, data, y_label, title)
end

return M
