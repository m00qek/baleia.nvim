local ansi = require("baleia.ansi")
local api = require("baleia.api")

local baleia = {}

local function either(value1, value2)
  if value1 == nil then
    return value2
  end
  return value1
end

local function with_colorscheme(theme)
  local colors = {}

  for index = 0, 255 do
    local color = vim.g["terminal_color_" .. index]
    colors[index] = color or theme[index]
  end

  return colors
end

local function with_options(opts, fn)
  return function(...)
    return fn(opts, ...)
  end
end

-- Creates a Baleia colorizer.
--
-- Parameters: ~
--   • {user_options}  Optional parameters map, accepts the following keys:
--                     • strip_ansi_codes: Remove ANSI color codes from text [default: true]
--                     • line_starts_at: |1-indexed| At which column start colorizing [default: 1]
--                     • chunk_size: Size, in lines, of each async batch [default: 500]
--                     • colors: Custom theme
--                     • async: Highlight asynchronously [default: true]
--                     • name: Prefix used to name highlight groups [default: "BaleiaColors"]
---@param user_options? baleia.Options
---@return Baleia
function baleia.setup(user_options)
  local opts = user_options or {}

  local name = either(opts.name, "BaleiaColors")

  opts.strip_ansi_codes = either(opts.strip_ansi_codes, true)
  opts.line_starts_at = either(opts.line_starts_at, 1)
  opts.namespace = vim.api.nvim_create_namespace(name)
  opts.colors = with_colorscheme(either(opts.colors, ansi.NR_8))
  opts.async = either(opts.async, true)
  opts.chunk_size = either(opts.chunk_size, 500)
  opts.name = name

  return {
    once = with_options(opts, api.once),
    automatically = with_options(opts, api.automatically),
    buf_set_lines = with_options(opts, api.buf_set_lines),
    buf_set_text = with_options(opts, api.buf_set_text),
  }
end

return baleia
