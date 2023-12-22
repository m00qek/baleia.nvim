local styles = require("baleia.styles")

local text = {}

text.strip_color_codes = function(raw_lines)
	local transformed_lines = {}

	for _, line in ipairs(raw_lines) do
		local stripped_line = line:gsub(styles.ANSI_CODES_PATTERN, "")
		table.insert(transformed_lines, stripped_line)
	end

	return transformed_lines
end

text.lastcolumn = function(lines)
	local lastline = lines[#lines]
	return #lastline
end

return text
