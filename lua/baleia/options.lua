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

function options.merge(opts1, opts2)
  local new_opts = {}

  for key, value in pairs(opts1) do
    new_opts[key] = value
  end

  for key, value in pairs(opts2) do
    new_opts[key] = value
  end

  new_opts.colors = merge_colors(opts1.colors, opts2.colors or {})
  return new_opts
end

function options.with_default(opts)
  local default_opts = {
    strip_ansi_codes = false,
    line_starts_at = 1,
    get_lines = lines.all(),
    colors = colors.theme(),
    name = "BaleiaColors"
  }

  return options.merge(default_opts, opts)
end

function options.conjure()
  local predicate = function(line) return line:sub(1, 1) == ";" end
  return {
    line_starts_at = 1,
    get_lines = lines.take_while(predicate),
    name = "ConjureLogColors"
  }
end

return options
