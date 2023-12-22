local styles = require("baleia.styles")

local locations = {}

local function linelocs(line, text)
	local extracted = {}

	local position = 1
	for ansi_sequence in text:gmatch(styles.ANSI_CODES_PATTERN) do
		local column = text:find(styles.ANSI_CODES_PATTERN, position)
		local style = styles.to_style(ansi_sequence)
		table.insert(extracted, {
			style = style,
			from = { line = line, column = column },
		})
		position = column + 1
	end

	return extracted
end

local function can_merge(previous, current)
	local on_the_same_line = current.from.line == previous.from.line
	local in_different_lines = current.from.line == previous.from.line + 1

	local no_text_between_locations = current.from.column == previous.from.column + previous.style.offset

	local current_location_at_start = current.from.column == 1
	local previous_location_at_the_end = previous.to.column == nil

	return (on_the_same_line and no_text_between_locations)
		or (in_different_lines and current_location_at_start and previous_location_at_the_end)
end

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

function locations.merge_neighbours(locs)
	local merged = {}

	local previous = nil
	for _, current in ipairs(locs) do
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

function locations.extract(lines)
	local lastcolumn = nil
	local lastline = #lines

	local extracted = {}

	for index = #lines, 1, -1 do
		local locs = linelocs(index, lines[index])

		for loc = #locs, 1, -1 do
			local location = locs[loc]

			location.to = { line = lastline, column = lastcolumn }
			table.insert(extracted, location)

			lastline = index
			lastcolumn = location.from.column - 1
			if lastcolumn < 1 then
				lastline = lastline - 1
				lastcolumn = nil
			end
		end
	end

	local reversed = {}

	local previous = nil
	for index = #extracted, 1, -1 do
		local current = extracted[index]

		if previous then
			current.style = styles.merge(previous.style, current.style)
		end

		reversed[#extracted - index + 1] = current
		previous = current
	end

	return reversed
end

function locations.with_offset(offset, locs)
	offset.line = offset.line or {}
	for _, loc in ipairs(locs) do
		local line_offset = offset.line[loc.from.line] or { column = 0 }
		loc.from.line = loc.from.line + offset.global.line
		loc.from.column = loc.from.column + offset.global.column + line_offset.column

		line_offset = offset.line[loc.to.line] or { column = 0 }
		loc.to.line = loc.to.line + offset.global.line
		loc.to.column = loc.to.column and loc.to.column + offset.global.column + line_offset.column
	end

	return locs
end

function locations.ignore_ansi_codes(locs)
	for _, loc in ipairs(locs) do
		loc.from.column = loc.from.column + loc.style.offset
	end

	return locs
end

function locations.strip_ansi_codes(locs)
	local line = locs[1].to.line
	local offset = 0

	for _, loc in ipairs(locs) do
		if line ~= loc.from.line then
			line = loc.from.line
			offset = 0
		end

		loc.from.column = loc.from.column - offset
		offset = offset + loc.style.offset

		if not loc.to.column then
			line = loc.to.line
			offset = 0
		elseif line ~= loc.to.line then
			line = loc.to.line
			offset = 0
		else
			loc.to.column = loc.to.column - offset
		end
	end

	return locs
end

return locations
