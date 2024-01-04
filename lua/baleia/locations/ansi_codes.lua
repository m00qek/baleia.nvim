local M = {}

---@param locations table<Location>
---@return table<Location>
function M.ignore(locations)
  for _, location in ipairs(locations) do
    location.from.column = location.from.column + location.style.offset
  end

  return locations
end

---@param locations table<Location>
---@return table<Location>
function M.strip(locations)
  local line_number = locations[1].to.line
  local offset = 0

  for _, location in ipairs(locations) do
    if line_number ~= location.from.line then
      line_number = location.from.line
      offset = 0
    end

    location.from.column = location.from.column - offset
    offset = offset + location.style.offset

    if not location.to.column or line_number ~= location.to.line then
      line_number = location.to.line
      offset = 0
    else
      location.to.column = location.to.column - offset
    end
  end

  return locations
end

return M
