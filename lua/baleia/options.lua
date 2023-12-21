local themes = require("baleia.styles.themes")
local log = require("baleia.log")

---@class UserOptions
---@field strip_ansi_codes? boolean
---@field line_starts_at? integer
---@field colors? Theme
---@field name? string
---@field log? string

---@class Options
---@field strip_ansi_codes boolean
---@field line_starts_at integer
---@field log_level string
---@field colors Theme
---@field logger any
---@field name string

local options = {}

---@param opts UserOptions
---@return Options
function options.with_default(opts)
	opts = opts or {}

	---@type Options
	local final_opts = {
		strip_ansi_codes = true,
		line_starts_at = 1,
		log_level = opts.log or "ERROR",
		colors = themes.with_colorscheme(themes.NR_8),
		logger = log.NULL_LOGGER,
		name = "BaleiaColors",
	}

	for key, _ in pairs(final_opts) do
		local user_value = opts[key]
		if user_value ~= nil then
			final_opts[key] = user_value
		end
	end

	return final_opts
end

return options
