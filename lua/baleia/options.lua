local logger = require("baleia.logger")
local nvim = require("baleia.nvim")
local themes = require("baleia.styles.themes")

---@class baleia.options.UI
---@field namespace integer
---@field log_level string
---@field logger baleia.Logger
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
  local log_level = either(options.log, "ERROR")
  local logname = name .. "Logs"

  ---@type baleia.options.Complete
  return {
    strip_ansi_codes = either(options.strip_ansi_codes, true),
    line_starts_at = either(options.line_starts_at, 1),
    namespace = nvim.create_namespace(name),
    log_level = log_level,
    logger = logger.new(logname, nvim.create_namespace(logname), log_level),
    colors = with_colorscheme(theme),
    async = either(options.async, true),
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
