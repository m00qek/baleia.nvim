local ansi = require("baleia.ansi")
local colors = require("baleia.colors")

local styles = {}

local function merge_value(from, to)
  if to.set then
    return to
  end
  return from
end

function styles.merge(from, to)
  local style = {
    foreground = merge_value(from.foreground, to.foreground),
    background = merge_value(from.background, to.background),
    special = merge_value(from.special, to.special),
    offset = to.offset or from.offset,
    modes = {},
  }

  for _, mode in pairs(ansi.modes) do
    style.modes[mode.attribute] = merge_value(from.modes[mode.attribute], to.modes[mode.attribute])
  end

  return style
end

function styles.none()
  local style = {
    foreground = { set = false, value = { name = 'none', cterm = 'none', gui = 'none' } },
    background = { set = false, value = { name = 'none', cterm = 'none', gui = 'none' } },
    special = { set = false, value = { name = 'none', cterm = 'none', gui = 'none' } },
    modes = {},
  }

  for _, mode in pairs(ansi.modes) do
    style.modes[mode.attribute] = { set = false, value = false, name = mode.definition.name }
  end

  return style
end

function styles.reset(offset)
  local style = {
    foreground = { set = true, value = { name = 'none', cterm = 'none', gui = 'none' } },
    background = { set = true, value = { name = 'none', cterm = 'none', gui = 'none' } },
    special = { set = true, value = { name = 'none', cterm = 'none', gui = 'none' } },
    modes = {},
    offset = offset,
  }

  for _, mode in pairs(ansi.modes) do
    style.modes[mode.attribute] = { set = true, value = false, name = mode.definition.name }
  end

  return style
end

function styles.to_style(ansi_sequence)
  local codes = {}
  for code in ansi_sequence:gmatch("[:0-9]+") do
    table.insert(codes, tonumber(code) or code)
  end

  local style = styles.none()
  local index = 1
  while index <= #codes do
    if codes[index] == 0 then
      style = styles.reset(#ansi_sequence);
      index = index + 1

    elseif ansi.modes[codes[index]] then
      local mode = ansi.modes[codes[index]]
      style.modes[mode.attribute] = mode.definition
      index = index + 1

    elseif ansi.background[codes[index]] then
      style.background = colors.from_xterm(ansi.background[codes[index]])
      index = index + 1
    elseif ansi.foreground[codes[index]] then
      style.foreground = colors.from_xterm(ansi.foreground[codes[index]])
      index = index + 1

    elseif codes[index] == 48 and codes[index + 1] == 5 then
      style.background = colors.from_xterm(codes[index + 2])
      index = index + 3
    elseif codes[index] == 38 and codes[index + 1] == 5 then
      style.foreground = colors.from_xterm(codes[index + 2])
      index = index + 3

    elseif codes[index] == 38 and codes[index + 1] == 2 then
      style.foreground = colors.from_truecolor(codes[index + 2], codes[index + 3], codes[index + 4])
      index = index + 5
    elseif codes[index] == 48 and codes[index + 1] == 2 then
      style.background = colors.from_truecolor(codes[index + 2], codes[index + 3], codes[index + 4])
      index = index + 5

    elseif codes[index] == 58 and codes[index + 1] == 5 then
      style.special = colors.from_xterm(codes[index + 2])
      index = index + 3

    else
      index = index + 1
    end
  end

  style.offset = #ansi_sequence
  return style
end

function styles.name(prefix, style)
  local modename = 0
  for _, value in pairs(style.modes) do
    if value.set and value.value then
      modename = bit.bor(modename, value.name)
    end
  end

  return prefix .. "_" .. modename .. "_" .. style.foreground.value.name .. "_" .. style.background.value.name .. "_" .. style.special.value.name
end

function styles.attributes(style, theme_colors)
  local attributes = {}

  for mode, value in pairs(style.modes) do
    if value.set then
      attributes[mode] = value.value
    end
  end

  if style.foreground.set then
    local value = style.foreground.value
    attributes.ctermfg = value.cterm
    attributes.foreground = value.gui
        and value.gui
        or (theme_colors[value.cterm] or value.inferred.gui)
  end

  if style.background.set then
    local value = style.background.value
    attributes.ctermbg = value.cterm
    attributes.background = value.gui
        and value.gui
        or (theme_colors[value.cterm] or value.inferred.gui)
  end

  if style.special.set then
    local value = style.special.value
    attributes.special = value.gui
        and value.gui
        or (theme_colors[value.cterm] or value.inferred.gui)
  end

  return attributes
end

return styles
