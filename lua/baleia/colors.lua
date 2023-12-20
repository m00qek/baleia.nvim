local xterm = require("baleia.styles.xterm")

local colors = {}

function colors.none()
	return {
		set = false,
		value = {
			name = "none",
			cterm = "none",
			gui = "none",
		},
	}
end

function colors.reset()
	return {
		set = true,
		value = {
			name = "none",
			cterm = "none",
			gui = "none",
		},
	}
end

function colors.from_xterm(code)
	return {
		set = true,
		value = {
			name = code,
			cterm = code,
			inferred = { gui = xterm.to_truecolor(code) },
		},
	}
end

function colors.from_truecolor(red, green, blue)
	local hexcode = string.format("%02x%02x%02x", red or 0, green or 0, blue or 0)
	return {
		set = true,
		value = {
			name = hexcode,
			cterm = xterm.from_rgb(red, green, blue),
			gui = "#" .. hexcode,
		},
	}
end

return colors
