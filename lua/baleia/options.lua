local colors = require("baleia.nvim.colors")

local options = {}

local function merge_colors(default, b)
  b.cterm = b.cterm or {}
  b.gui = b.gui or {}

  local newcolors = { cterm = { }, gui = { } }

  for name, color in pairs(default) do
    newcolors.cterm[name] = b.cterm[name] or name
    newcolors.gui[name] = b.gui[name] or color
  end

  return newcolors
end

function options.with_default(opts)
  opts = opts or { }
  return {
    strip_ansi_codes = opts.strip_ansi_codes or true,
    line_starts_at = opts.line_starts_at or 1,
    colors = merge_colors(colors.theme(), { }),
    name = opts.name or "BaleiaColors"
  }
end

return options
