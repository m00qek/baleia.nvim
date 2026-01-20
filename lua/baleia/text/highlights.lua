local styles = require("baleia.styles")

---@class baleia.text.Mark
---@field highlight string
---@field firstcolumn integer
---@field lastcolumn? integer
---@field line integer

local M = {}

---@param highlight_name string
---@param location baleia.locations.Location
---@return baleia.text.Mark
local function single_line(highlight_name, location)
  return {
    highlight = highlight_name,
    firstcolumn = location.from.column,
    lastcolumn = location.to.column,
    line = location.from.line,
  }
end

---@param line_starts_at integer
---@param highlight_name string
---@param location baleia.locations.Location
---@return baleia.text.Mark[]
local function multi_line(line_starts_at, highlight_name, location)
  local highlights = {}

  table.insert(highlights, {
    highlight = highlight_name,
    firstcolumn = location.from.column,
    line = location.from.line,
  })

  for line = location.from.line + 1, location.to.line - 1 do
    table.insert(highlights, {
      highlight = highlight_name,
      firstcolumn = line_starts_at,
      line = line,
    })
  end

  if not location.to.column or line_starts_at < location.to.column then
    table.insert(highlights, {
      highlight = highlight_name,
      firstcolumn = line_starts_at,
      lastcolumn = location.to.column,
      line = location.to.line,
    })
  end

  return highlights
end

---@param options baleia.options.Basic
---@param locations baleia.locations.Location[]
---@return baleia.text.Mark[], { [string]: baleia.styles.Highlight }
function M.from_locations(options, locations)
  ---@type { [string]: baleia.styles.Highlight }
  local highlights = {}

  ---@type baleia.text.Mark[]
  local marks = {}

  for _, location in pairs(locations) do
    local highlight_name = styles.name(options.name, location.style)

    if location.from.line == location.to.line then
      local mark = single_line(highlight_name, location)
      if not mark.lastcolumn or mark.firstcolumn <= mark.lastcolumn then
        table.insert(marks, mark)
      end
    else
      local new_marks = multi_line(options.line_starts_at, highlight_name, location)
      for _, mark in ipairs(new_marks) do
        if not mark.lastcolumn or mark.firstcolumn <= mark.lastcolumn then
          table.insert(marks, mark)
        end
      end
    end

    highlights[highlight_name] = styles.attributes(location.style, options.colors)
  end

  return marks, highlights
end

return M
