local styles = require("baleia.styles")

local M = {}

---@param previous baleia.locations.Location
---@param current baleia.locations.Location
---@return boolean
local function can_merge(previous, current)
  local on_the_same_line = current.from.line == previous.from.line
  local in_different_lines = current.from.line == previous.from.line + 1

  local no_text_between_locations = current.from.column == previous.from.column + previous.style.offset

  local current_location_at_start = current.from.column == 1
  local previous_location_at_the_end = previous.to.column == previous.from.column + previous.style.offset - 1

  return (on_the_same_line and no_text_between_locations)
    or (in_different_lines and current_location_at_start and previous_location_at_the_end)
end

---@param previous baleia.locations.Location
---@param current baleia.locations.Location
---@return baleia.locations.Location
local function merge(previous, current)
  local style = styles.merge(previous.style, current.style)

  local from = previous.from
  local to = current.to

  if current.from.line == previous.from.line then
    style.offset = previous.style.offset + current.style.offset
    to.offset = previous.to.offset + current.to.offset
    from.offset = previous.from.offset + current.from.offset
  else
    to.offset = current.to.offset
    from.offset = previous.from.offset
  end

  return {
    style = style,
    from = from,
    to = to,
  }
end

---@param locations baleia.locations.Location[]
---@return baleia.locations.Location[]
function M.merge(locations)
  local merged = {}

  local previous = nil
  for _, current in ipairs(locations) do
    if previous and can_merge(previous, current) then
      previous = merge(previous, current)
    elseif previous then
      table.insert(merged, previous)
      previous = current
    else
      previous = current
    end
  end

  if previous then
    table.insert(merged, previous)
  end

  return merged
end

return M
