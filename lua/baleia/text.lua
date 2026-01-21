local styles = require("baleia.styles")

local M = {}

local function strip_color_codes(raw_lines)
  local lines = {}

  for _, line in ipairs(raw_lines) do
    local stripped_line = line:gsub(styles.ANSI_CODES_PATTERN, "")
    table.insert(lines, stripped_line)
  end

  return lines
end

---@param lines string[]
---@return integer
function M.lastcolumn(lines)
  local lastline = lines[#lines]
  return #lastline
end

---@param options baleia.options.Basic
---@param lines string[]
---@return string[]
function M.content(options, lines)
  return options.strip_ansi_codes and strip_color_codes(lines) or lines
end

return M
