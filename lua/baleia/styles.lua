local ansi = require("baleia.styles.ansi")
local colors = require("baleia.styles.colors")
local modes = require("baleia.styles.modes")

local styles = {}

styles.ANSI_CODES_PATTERN = ansi.PATTERN

---@class Style
---@field background ColorAttribute
---@field foreground ColorAttribute
---@field special ColorAttribute
---@field modes table<string, ModeAttribute>
---@field offset integer

---@class Highlight
---@field foreground? string
---@field background? string
---@field special? string
---@field ctermfg? string
---@field ctermbg? string
---@field bold? boolean
---@field standout? boolean
---@field underline? boolean
---@field undercurl? boolean
---@field underdouble? boolean
---@field underdotted? boolean
---@field underdashed? boolean
---@field strikethrough? boolean
---@field italic? boolean
---@field reverse? boolean

local function merge_value(from, to)
	if to.set then
		return to
	end
	return from
end

---@param from Style
---@param to Style
---@return Style
function styles.merge(from, to)
	local style = {
		foreground = merge_value(from.foreground, to.foreground),
		background = merge_value(from.background, to.background),
		special = merge_value(from.special, to.special),
		offset = to.offset or from.offset,
		modes = {},
	}

	for name, attr in pairs(from.modes) do
		style.modes[name] = attr
	end

	for name, attr in pairs(to.modes) do
		style.modes[name] = merge_value(from.modes[name], attr)
	end

	return style
end

---@return Style
function styles.none()
	---@type Style
	local style = {
		foreground = colors.none(),
		background = colors.none(),
		special = colors.none(),
		offset = 0,
		modes = {},
	}

	---TODO: WTF
	for _, mode in pairs(ansi.modes) do
		for name, attr in pairs(mode.definition) do
			if style.modes[name] == nil or style.modes[name].value.tag > attr.value.tag then
				style.modes[name] = modes.ignore(attr.value.tag)
			end
		end
	end

	return style
end

---@param offset integer
---@return Style
function styles.reset(offset)
	---@type Style
	local style = {
		foreground = colors.reset(),
		background = colors.reset(),
		special = colors.reset(),
		offset = offset,
		modes = {},
	}

	for _, mode in pairs(ansi.modes) do
		for name, attr in pairs(mode.definition) do
			if style.modes[name] == nil or style.modes[name].value.tag > attr.value.tag then
				style.modes[name] = modes.turn_off(attr.value.tag)
			end
		end
	end

	return style
end

---@param ansi_sequence string
---@return Style
function styles.to_style(ansi_sequence)
	local codes = {}
	for code in ansi_sequence:gmatch("[:0-9]+") do
		table.insert(codes, tonumber(code) or code)
	end

	local style = styles.none()
	local index = 1
	while index <= #codes do
		if codes[index] == 0 then
			style = styles.reset(#ansi_sequence)
		elseif ansi.colors[codes[index]] then
			local entry = ansi.colors[codes[index]]

			if entry.definition then
				for attr, value in pairs(entry.definition) do
					style[attr] = value
				end
			elseif entry.generators then
				local flag = codes[index + 1]
				local generator = entry.generators[flag]

				local params = {}
				for i = 1, generator.params, 1 do
					params[i] = codes[index + 1 + i]
				end

				for attr, fn in pairs(generator.fn) do
					style[attr] = fn(unpack(params))
				end

				-- current index + 1 flag + N parameters
				index = index + 1 + generator.params
			end
		elseif ansi.modes[codes[index]] then
			local mode = ansi.modes[codes[index]]
			for name, attr in pairs(mode.definition) do
				style.modes[name] = attr
			end
		end

		index = index + 1
	end

	style.offset = #ansi_sequence
	return style
end

---@param prefix string
---@param style Style
---@return string
function styles.name(prefix, style)
	local modename = 0
	for _, attr in pairs(style.modes) do
		if attr.set then
			modename = bit.bor(modename, attr.value.tag)
		end
	end

	return prefix
		.. "_"
		.. modename
		.. "_"
		.. style.foreground.value.name
		.. "_"
		.. style.background.value.name
		.. "_"
		.. style.special.value.name
end

---@param style Style
---@param theme Theme
---@return Highlight
function styles.attributes(style, theme)
	---@type Highlight
	local attributes = {}

	for name, attr in pairs(style.modes) do
		if attr.set then
			attributes[name] = attr.value.enabled
		end
	end

	if style.foreground.set then
		local color = style.foreground.value
		attributes.ctermfg = colors.cterm(color)
		attributes.foreground = colors.gui(color, theme)
	end

	if style.background.set then
		local color = style.background.value
		attributes.ctermbg = colors.cterm(color)
		attributes.background = colors.gui(color, theme)
	end

	if style.special.set then
		local color = style.special.value
		attributes.special = colors.gui(color, theme)
	end

	return attributes
end

return styles
