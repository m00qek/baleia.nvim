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

	local final_opts = {
		strip_ansi_codes = true,
		line_starts_at = 1,
		log_level = opts.log or "ERROR",
		colors = themes.with_colorscheme(themes.NR_8),
		name = "BaleiaColors",
	}

	final_opts.namespace = nvim.create_namespace(final_opts.name)
	final_opts.logger = logger.new(final_opts.name .. "Log", final_opts.ns, final_opts.log_level)

	for key, _ in pairs(final_opts) do
		local user_value = opts[key]
		if user_value ~= nil then
			final_opts[key] = user_value
		end
	end

	return final_opts
end

return options
