local M = {}

---@param locations Location[]
---@return Location[]
function M.ignore(locations)
  for _, location in ipairs(locations) do
    location.from.column = location.from.column + location.from.offset
  end

  return locations
end

---@param locations Location[]
---@return Location[]
function M.strip(locations)
  local current_line = 0
  local lineoffset = 0

  for _, location in ipairs(locations) do
    if current_line ~= location.from.line then
      current_line = location.from.line
      lineoffset = 0
    end

    location.from.column = location.from.column - lineoffset

    if location.from.line ~= location.to.line then
      current_line = location.to.line
      lineoffset = 0
    end

    print(location.from.column, lineoffset)
    lineoffset = lineoffset + location.to.offset
    location.to.column = location.to.column - lineoffset
  end

  return locations
end

return M
