---@class Offset
---@field line integer
---@field column integer

---@class OffsetConfig
---@field global Offset
---@field lines? table<integer, Offset>

local offsets = {}

---@param offset Offset
---@param position StrictPosition|LoosePosition
local function update_position(position, offset)
	position.line = position.line + offset.line
	position.column = position.column and position.column + offset.column
end

---@param offset OffsetConfig
---@param locations table<Location>
---@return table<Location>
function offsets.apply(offset, locations)
	local lines_offset = offset.lines or {}
	local default_offset = offset.global or { line = 0, column = 0 }

	for _, location in ipairs(locations) do
		update_position(location.from, lines_offset[location.from.line] or default_offset)
		update_position(location.to, lines_offset[location.to.line] or default_offset)
	end

	return locations
end

return offsets
