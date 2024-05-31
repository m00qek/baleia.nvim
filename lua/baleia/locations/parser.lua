local styles = require("baleia.styles")

---@class StrictPosition
---@field line integer
---@field column integer
---@field offset integer?

---@class LoosePosition
---@field line integer
---@field column? integer

---@class Location
---@field text string
---@field style Style
---@field from StrictPosition
---@field to StrictPosition

local M = {}

--- Reverses a list.
---@generic T
---@param list T[]
---@return (fun(t: T[], i: integer): integer?, T?), T[], integer
local function rpairs(list)
  return function(t, i)
    i = i - 1
    if i ~= 0 then
      return i, t[i]
    end
  end, list, #list + 1
end

---@param line_number integer
---@param text string
---@return Location[]
local function parse_line(line_number, text)
  local locations = {}

  local position = 1
  for ansi_sequence in string.gmatch(text, styles.ANSI_CODES_PATTERN) do
    local column_number = string.find(text, styles.ANSI_CODES_PATTERN, position)
    local style = styles.to_style(ansi_sequence)
    table.insert(locations, {
      style = style,
      from = { line = line_number, column = column_number, offset = style.offset },
    })
    position = column_number + 1
  end

  return locations
end

---@param lines string[]
---@return Location[]
local function parse_all(lines)
  local lastline = #lines
  local lastcolumn = #lines[lastline]

  local locations = {}

  for line_number, current_line in rpairs(lines) do
    for _, current_location in rpairs(parse_line(line_number, current_line)) do
      current_location.to = {
        line = lastline,
        column = lastcolumn,
        offset = lastline == current_location.from.line and current_location.style.offset or 0,
      }
      table.insert(locations, current_location)

      lastline = line_number
      lastcolumn = current_location.from.column - 1
      if lastcolumn < 1 then
        lastline = lastline - 1

        if lines[lastline] then
          lastcolumn = #lines[lastline]
        else
          lastcolumn = 0
        end
      end
    end
  end

  return locations
end

---@param locations Location[]
---@return Location[]
local function merge_styles(locations)
  local merged = {}

  local previous = nil
  for _, current in rpairs(locations) do
    if previous then
      current.style = styles.merge(previous.style, current.style)
    end
    table.insert(merged, current)
    previous = current
  end

  return merged
end

---@param lines string[]
---@return Location[]
function M.parse(lines)
  if not next(lines) then
    return {}
  end

  local locations = parse_all(lines)
  return merge_styles(locations)
end

return M
