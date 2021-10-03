local colors = require("baleia.nvim.colors")
local ansi = require("baleia.colors.ansi")

local options = {}

function options.with_default(opts)
  opts = opts or { }
  return {
    strip_ansi_codes = opts.strip_ansi_codes or true,
    line_starts_at = opts.line_starts_at or 1,
    colors = colors.theme(ansi.NR_8),
    name = opts.name or "BaleiaColors"
  }
end

return options
