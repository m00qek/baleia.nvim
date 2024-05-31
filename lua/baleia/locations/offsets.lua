---@class baleia.offsets.Offset
---@field line integer
---@field column integer

---@class baleia.offsets.Config
---@field global baleia.offsets.Offset
---@field lines? { [integer]: baleia.offsets.Offset }

local M = {}

---@param offset baleia.offsets.Offset
---@param position baleia.locations.Position
local function update_position(position, offset)
  local line_offset = offset.line or 0
  local column_offset = offset.column or 0

  position.line = position.line + line_offset
  position.column = position.column and position.column + column_offset
end

---@param config baleia.offsets.Config
---@param locations baleia.locations.Location[]
---@return baleia.locations.Location[]
function M.apply(config, locations)
  local lines_offset = config.lines or {}
  local default_offset = config.global or { line = 0, column = 0 }

  for _, location in ipairs(locations) do
    update_position(location.from, lines_offset[location.from.line] or default_offset)
    update_position(location.to, lines_offset[location.to.line] or default_offset)
  end

  return locations
end

return M
