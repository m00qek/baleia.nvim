local highlights = require("baleia.text.highlights")
local locations = require("baleia.locations")
local styles = require("baleia.styles")

---@class TextColors
---@field highlights table<string, HighlightAttributes>
---@field marks table<Mark>

local M = {}

local function strip_color_codes(raw_lines)
  local lines = {}

  for _, line in ipairs(raw_lines) do
    local stripped_line = line:gsub(styles.ANSI_CODES_PATTERN, "")
    table.insert(lines, stripped_line)
  end

  return lines
end

function M.lastcolumn(lines)
  local lastline = lines[#lines]
  return #lastline
end

---@param options BasicOptions
---@param lines table<string>
---@return table<string>
function M.content(options, lines)
  return options.strip_ansi_codes and strip_color_codes(lines) or lines
end

---@param options BasicOptions
---@param lines table<string>
---@param offset OffsetConfig
---@return table<Mark>, table<string, HighlightAttributes>
function M.colors(options, lines, offset)
  local locs = locations.extract(options, offset, lines)
  if not next(locs) then
    return {}, {}
  end

  return highlights.from_locations(options, locs)
end

return M
