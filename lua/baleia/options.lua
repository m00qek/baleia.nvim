local themes = require("baleia.styles.themes")
local logger = require("baleia.logger")
local nvim = require("baleia.nvim")

---@class CompleteOptions
---@field strip_ansi_codes boolean
---@field line_starts_at integer
---@field namespace integer
---@field log_level string
---@field colors Theme
---@field logger Logger
---@field async boolean
---@field name string

---@class BasicOptions
---@field strip_ansi_codes boolean
---@field line_starts_at integer
---@field colors Theme
---@field name string

---@alias Options BasicOptions|CompleteOptions

local function either(value1, value2)
	if value1 == nil then
		return value2
	end
	return value1
end

local options = {}

---@param user_options? UserOptions
---@return Options
function options.with_defaults(user_options)
	print(vim.inspect(user_options))
	local opts = user_options or {}

	local theme = either(opts.colors, themes.NR_8)
	local name = either(opts.name, "BaleiaColors")
	local log_level = either(opts.log, "ERROR")
	local logname = name .. "Logs"

	---@type Options
	return {
		strip_ansi_codes = either(opts.strip_ansi_codes, true),
		line_starts_at = either(opts.line_starts_at, 1),
		namespace = nvim.create_namespace(name),
		log_level = log_level,
		logger = logger.new(logname, nvim.create_namespace(logname), log_level),
		colors = themes.with_colorscheme(theme),
		async = either(opts.async, true),
		name = name,
	}
end

---@param opts Options
---@return BasicOptions
function options.basic(opts)
	return {
		strip_ansi_codes = opts.strip_ansi_codes,
		line_starts_at = opts.line_starts_at,
		colors = opts.colors,
		name = opts.name,
	}
end

return options
