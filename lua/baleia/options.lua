local themes = require("baleia.styles.themes")

---@class baleia.options.UI
---@field chunk_size integer
---@field namespace integer
---@field async boolean

---@class baleia.options.Basic
---@field strip_ansi_codes boolean
---@field line_starts_at integer
---@field colors baleia.styles.Theme
---@field name string

---@alias baleia.options.Complete baleia.options.Basic | baleia.options.UI

local M = {}

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

---@param user_options? baleia.Options
---@return baleia.options.Complete
function M.with_defaults(user_options)
  local options = user_options or {}

  local theme = either(options.colors, themes.NR_8)
  local name = either(options.name, "BaleiaColors")

  ---@type baleia.options.Complete
  return {
    strip_ansi_codes = either(options.strip_ansi_codes, true),
    line_starts_at = either(options.line_starts_at, 1),
    namespace = vim.api.nvim_create_namespace(name),
    colors = with_colorscheme(theme),
    async = either(options.async, true),
    chunk_size = either(options.chunk_size, 500),
    name = name,
  }
end

---@param options baleia.options.Complete
---@return baleia.options.Basic
function M.basic(options)
  return {
    strip_ansi_codes = options.strip_ansi_codes,
    line_starts_at = options.line_starts_at,
    colors = options.colors,
    name = options.name,
  }
end

return M
