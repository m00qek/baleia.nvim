local styles = require("baleia.styles")

local M = {}

local function strip_color_codes(raw_lines)
  local lines = {}

  for _, line in ipairs(raw_lines) do
    if line then
      local stripped_line = line:gsub(styles.PATTERN, "")
      table.insert(lines, stripped_line)
    else
      table.insert(lines, "")
    end
  end

  return lines
end

---@param options baleia.options.Basic
---@param lines string[]
---@return string[]
function M.content(options, lines)
  return options.strip_ansi_codes and strip_color_codes(lines) or lines
end

return M
