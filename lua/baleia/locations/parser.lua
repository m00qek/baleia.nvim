local ansi_codes = require("baleia.locations.ansi_codes")
local styles = require("baleia.styles")

---@class StrictPosition
---@field line integer
---@field column integer

---@class LoosePosition
---@field line integer
---@field column? integer

---@class Location
---@field style Style
---@field from StrictPosition
---@field to LoosePosition

local M = {}

local function rpairs(table)
  return function(t, i)
    i = i - 1
    if i ~= 0 then
      return i, t[i]
    end
  end, table, #table + 1
end

---@param lines string[]
---@return Location[]
local function parse_all(lines)
  return ansi_codes.map(lines, function(ansi_sequence, from, to)
    ---@type Location
    return {
      style = styles.to_style(ansi_sequence),
      from = from,
      to = to,
    }
  end, { backwards = true })
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
