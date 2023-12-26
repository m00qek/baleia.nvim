local xterm = require("baleia.styles.xterm")

local M = {}

---@class TermColor
---@field name string
---@field cterm string
---@field inferred string

---@class GuiColor
---@field name string
---@field gui string
---@field inferred string

---@class ColorAttribute
---@field set boolean
---@field value TermColor | GuiColor

-- Returns the GUI color hexcode
--
-- Parameters: ~
--   • {color}  Color
--   • {theme}  Custom theme
---@param color TermColor | GuiColor
---@param theme Theme
---@return string
function M.gui(color, theme)
	if color.gui then
		return color.gui
	end

	return theme[color.cterm] or color.inferred
end

-- Returns the cterm color code
--
-- Parameters: ~
--   • {color}  Color
---@param color TermColor | GuiColor
---@return string
function M.cterm(color)
	if color.cterm then
		return color.cterm
	end

	return color.inferred
end

-- Identity color: when applied does not change anything
--
---@return ColorAttribute
function M.none()
	return {
		set = false,
		value = {
			name = "none",
			cterm = "none",
			gui = "none",
		},
	}
end

-- Default highlight color
--
---@return ColorAttribute
function M.reset()
	return {
		set = true,
		value = {
			name = "none",
			cterm = "none",
			gui = "none",
		},
	}
end

-- Create a Color attribute from an ANSI 256 color code
--
-- Parameters: ~
--   • {code}  ANSI color code (between 0 and 255)
---@param code integer
---@return ColorAttribute
function M.from_xterm(code)
	return {
		set = true,
		value = {
			name = code,
			cterm = code,
			inferred = xterm.to_truecolor(code),
		},
	}
end

-- Create a Color attribute from a RGB triplet
--
-- Parameters: ~
--   • {red}    Red color component (between 0 and 255)
--   • {green}  Red color component (between 0 and 255)
--   • {blue}   Red color component (between 0 and 255)
---@param red integer
---@param green integer
---@param blue integer
---@return ColorAttribute
function M.from_truecolor(red, green, blue)
	local hexcode = string.format("%02x%02x%02x", red or 0, green or 0, blue or 0)
	return {
		set = true,
		value = {
			name = hexcode,
			gui = "#" .. hexcode,
			inferred = xterm.from_rgb(red, green, blue),
		},
	}
end

return M
