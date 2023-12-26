local locations = require("baleia.locations")
local styles = require("baleia.styles")

local highlight = {}

local function single_line(name, location)
	return {
		firstcolumn = location.from.column,
		lastcolumn = location.to.column,
		line = location.from.line,
		name = name,
	}
end

local function multi_line(line_starts_at, name, location)
	local highlights = {}

	table.insert(highlights, {
		firstcolumn = location.from.column,
		line = location.from.line,
		name = name,
	})

	for line = location.from.line + 1, location.to.line - 1 do
		table.insert(highlights, {
			firstcolumn = line_starts_at,
			line = line,
			name = name,
		})
	end

	if not location.to.column or line_starts_at < location.to.column then
		table.insert(highlights, {
			firstcolumn = line_starts_at,
			lastcolumn = location.to.column,
			line = location.to.line,
			name = name,
		})
	end

	return highlights
end

local function to_highlights(options, locs)
	local definitions = {}
	local all_highlights = {}

	for _, location in pairs(locs) do
		local name = styles.name(options.name, location.style)

		if location.from.line == location.to.line then
			table.insert(all_highlights, single_line(name, location))
		else
			local highlights = multi_line(options.line_starts_at, name, location)
			for _, h in ipairs(highlights) do
				table.insert(all_highlights, h)
			end
		end

		definitions[name] = styles.attributes(location.style, options.colors)
	end

	return {
		definitions = definitions,
		highlights = all_highlights,
	}
end

function highlight.all(options, offset, lines)
	local locs = locations.extract(options, offset, lines)
	if not next(locs) then
		return nil
	end

	return to_highlights(options, locs)
end

return highlight
