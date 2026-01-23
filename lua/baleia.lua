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

---Creates a Baleia colorizer.
---@param user_options? baleia.UserOptions
---@return Baleia
function baleia.setup(user_options)
  user_options = user_options or {}
  local opts = {}

  local name = either(user_options.name, "BaleiaColors")

  opts.strip_ansi_codes = either(user_options.strip_ansi_codes, true)
  opts.line_starts_at = either(user_options.line_starts_at, 1)
  opts.namespace = vim.api.nvim_create_namespace(name)
  opts.colors = with_colorscheme(either(user_options.colors, ansi.NR_8))
  opts.async = either(user_options.async, true)
  opts.chunk_size = either(user_options.chunk_size, 500)
  opts.highlight_cache = {}
  opts.name = name

  return {
    once = with_options(opts, api.once),
    automatically = with_options(opts, api.automatically),
    buf_set_lines = with_options(opts, api.buf_set_lines),
    buf_set_text = with_options(opts, api.buf_set_text),
    -- just for retro compatibility:
    logger = {
      show = function()
        vim.notify("Please use :messages to check logs", vim.log.levels.WARN)
      end,
    },
  }
end

return baleia
