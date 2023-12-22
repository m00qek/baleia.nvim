local options = require("baleia.options")
local api = require("baleia.api")

local baleia = {}

local function with_options(opts, fn)
	return function(...)
		return fn(opts, ...)
	end
end

-- Creates a Baleia colorizer.
--
-- Parameters: ~
--   • {user_options}  Optional parameters map, accepts the following keys:
--                     • strip_ansi_codes: Should remove ANSI color codes from text?
--                     • line_starts_at: |1-indexed| At which column start colorizing
--                     • colors: Custom theme
--                     • name: Prefix used to name highlight groups
--                     • log: Log level (ERROR, WARN, INFO or DEBUG)
---@param user_options? UserOptions
---@return Baleia
function baleia.setup(user_options)
	local opts = options.with_defaults(user_options)

	return {
		once = with_options(opts, api.once),
		automatically = with_options(opts, api.automatically),
		buf_set_lines = with_options(opts, api.buf_set_lines),
		buf_set_text = with_options(opts, api.buf_set_text),
		logger = opts.logger,
	}
end

return baleia
