local themes = require("baleia.styles.themes")
local logger = require("baleia.logger")
local nvim = require("baleia.nvim")

---@class Options
---@field strip_ansi_codes boolean
---@field line_starts_at integer
---@field namespace integer
---@field log_level string
---@field colors Theme
---@field logger Logger
---@field name string

local options = {}

---@param user_options? UserOptions
---@return Options
function options.with_defaults(user_options)
	local opts = user_options or {}

	local theme = opts.colors or themes.NR_8
	local name = opts.name or "BaleiaColors"
	local log_level = opts.log or "ERROR"
	local logname = name .. "Logs"

	---@type Options
	return {
		strip_ansi_codes = opts.strip_ansi_codes or true,
		line_starts_at = opts.line_starts_at or 1,
		namespace = nvim.create_namespace(name),
		log_level = log_level,
		logger = logger.new(logname, nvim.create_namespace(logname), log_level),
		colors = themes.with_colorscheme(theme),
		name = name,
	}
end

return options
