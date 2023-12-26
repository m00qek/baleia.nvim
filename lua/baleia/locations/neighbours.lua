local styles = require("baleia.styles")

local M = {}

---@param previous Location
---@param current Location
---@return boolean
local function can_merge(previous, current)
	local on_the_same_line = current.from.line == previous.from.line
	local in_different_lines = current.from.line == previous.from.line + 1

	local no_text_between_locations = current.from.column == previous.from.column + previous.style.offset

	local current_location_at_start = current.from.column == 1
	local previous_location_at_the_end = previous.to.column == nil

	return (on_the_same_line and no_text_between_locations)
		or (in_different_lines and current_location_at_start and previous_location_at_the_end)
end

---@param previous Location
---@param current Location
---@return Location
local function merge(previous, current)
	local style = styles.merge(previous.style, current.style)
	if current.from.line == previous.from.line then
		style.offset = previous.style.offset + current.style.offset
	end

	return {
		style = style,
		from = previous.from,
		to = current.to,
	}
end

---@param locations table<Location>
---@return table<Location>
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
