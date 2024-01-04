local ansi_codes = require("baleia.locations.ansi_codes")
local neighbours = require("baleia.locations.neighbours")
local offsets = require("baleia.locations.offsets")
local parser = require("baleia.locations.parser")

local M = {}

---@param options BasicOptions
---@param offset OffsetConfig
---@param lines table<string>
---@return table<Location>
function M.extract(options, offset, lines)
  local locs = parser.parse(lines)
  if not next(locs) then
    return {}
  end

  locs = neighbours.merge(locs)

  if options.strip_ansi_codes then
    locs = ansi_codes.strip(locs)
  else
    locs = ansi_codes.ignore(locs)
  end

  return offsets.apply(offset, locs)
end

return M
