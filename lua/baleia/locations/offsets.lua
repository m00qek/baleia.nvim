---@class Offset
---@field line integer
---@field column integer

---@class OffsetConfig
---@field global Offset
---@field lines? { [integer]: Offset }

local M = {}

---@param offset Offset
---@param position StrictPosition|LoosePosition
local function update_position(position, offset)
  local line_offset = offset.line or 0
  local column_offset = offset.column or 0

  position.line = position.line + line_offset
  position.column = position.column and position.column + column_offset
end

---@param offset OffsetConfig
---@param locations Location[]
---@return Location[]
function M.apply(offset, locations)
  local lines_offset = offset.lines or {}
  local default_offset = offset.global or { line = 0, column = 0 }

  for _, location in ipairs(locations) do
    update_position(location.from, lines_offset[location.from.line] or default_offset)
    update_position(location.to, lines_offset[location.to.line] or default_offset)
  end

  return locations
end

return M
