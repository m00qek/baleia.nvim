local styles = require("baleia.styles")

---@class StrictPosition
---@field line integer
---@field column integer

---@class LoosePosition
---@field line integer
---@field column? integer

---@class Location
---@field text string
---@field style Style
---@field from StrictPosition
---@field to LoosePosition

local function rpairs(table)
	return function(t, i)
		i = i - 1
		if i ~= 0 then
			return i, t[i]
		end
	end, table, #table + 1
end

---@param line_number integer
---@param text string
---@return table<Location>
local function parse_line(line_number, text)
	local locations = {}

	local position = 1
	for ansi_sequence in string.gmatch(text, styles.ANSI_CODES_PATTERN) do
		local column_number = string.find(text, styles.ANSI_CODES_PATTERN, position)
		table.insert(locations, {
			style = styles.to_style(ansi_sequence),
			from = { line = line_number, column = column_number },
		})
		position = column_number + 1
	end

	return locations
end

---@param lines table<string>
---@return table<Location>
local function parse_all(lines)
	local lastline = #lines
	local lastcolumn = nil

	local locations = {}

	for line_number, current_line in rpairs(lines) do
		for _, current_location in rpairs(parse_line(line_number, current_line)) do
			current_location.to = { line = lastline, column = lastcolumn }
			table.insert(locations, current_location)

			lastline = line_number
			lastcolumn = current_location.from.column - 1
			if lastcolumn < 1 then
				lastline = lastline - 1
				lastcolumn = nil
			end
		end
	end

	return locations
end

---@param locations table<Location>
---@return table<Location>
local function merge_styles(locations)
	local merged = {}

	local previous = nil
	for _, current in rpairs(locations) do
		if previous then
			current.style = styles.merge(previous.style, current.style)
		end
		table.insert(merged, current)
		previous = current
	end

	return merged
end

local parser = {}

---@param lines table<string>
---@return table<Location>
function parser.parse(lines)
	if not next(lines) then
		return {}
	end

	local locations = parse_all(lines)
	return merge_styles(locations)
end

return parser
