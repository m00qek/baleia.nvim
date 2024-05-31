local highlights = require("baleia.text.highlights")
local locations = require("baleia.locations")
local styles = require("baleia.styles")

---@class baleia.text.Colors
---@field highlights { [string]: baleia.styles.Highlight }
---@field marks baleia.text.Mark[]

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

---@param options baleia.options.Basic
---@param lines string[]
---@param offset baleia.offsets.Config
---@return baleia.text.Mark[], { [string]: baleia.styles.Highlight }
function M.colors(options, lines, offset)
  local locs = locations.extract(options, offset, lines)
  if not next(locs) then
    return {}, {}
  end

  return highlights.from_locations(options, locs)
end

return M
