local colors = require("baleia.nvim.colors")
local lines = require("baleia.lines")

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
  return {
    strip_ansi_codes = opts.strip_sequences or false,
    line_starts_at = opts.line_starts_at or 1,
    get_lines = opts.get_lines or lines.all(),
    colors = merge_colors(colors.theme(), { }),
    name = opts.name or "BaleiaColors"
  }
end

function options.conjure()
  local predicate = function(line) return line:sub(1, 1) == ";" end
  return {
    line_starts_at = 3,
    get_lines = lines.take_while(predicate),
    name = "ConjureLogColors"
  }
end

return options
