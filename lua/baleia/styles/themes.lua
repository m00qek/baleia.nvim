local themes = {}

---@alias Theme table<integer, string>

-- Completes {theme} with current colorscheme
--
-- Parameters: ~
--   • {theme}  Custom theme
---@param theme Theme
---@return Theme
function themes.with_colorscheme(theme)
	local colors = {}

	for index = 0, 255 do
		local color = vim.g["terminal_color_" .. index]
		colors[index] = color or theme[index]
	end

	return colors
end

---@type Theme
themes.NR_16 = {
	[00] = "Black",
	[01] = "DarkBlue",
	[02] = "DarkGreen",
	[03] = "DarkCyan",
	[04] = "DarkRed",
	[05] = "DarkMagenta",
	[06] = "DarkYellow",
	[07] = "LightGrey",
	[08] = "DarkGrey",
	[09] = "LightBlue",
	[10] = "LightGreen",
	[11] = "LightCyan",
	[12] = "LightRed",
	[13] = "LightMagenta",
	[14] = "LightYellow",
	[15] = "White",
}

---@type Theme
themes.NR_8 = {
	[00] = "Black",
	[01] = "DarkRed",
	[02] = "DarkGreen",
	[03] = "DarkYellow",
	[04] = "DarkBlue",
	[05] = "DarkMagenta",
	[06] = "DarkCyan",
	[07] = "LightGrey",
	[08] = "DarkGrey",
	[09] = "LightRed",
	[10] = "LightGreen",
	[11] = "LightYellow",
	[12] = "LightBlue",
	[13] = "LightMagenta",
	[14] = "LightCyan",
	[15] = "White",
}

return themes
