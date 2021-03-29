local ansi = require('baleia.ansi')

local styles = {}

function styles.none() 
  return {
    foreground = { set = false, value = ansi.foreground[0]},
    background = { set = false, value = ansi.background[0]},
    modes = {
      bold =      { set = false, value = false }, 
      italic =    { set = false, value = false },
      underline = { set = false, value = false }
    },
  }
end

function styles.reset() 
  return {
    foreground = { set = true, value = ansi.foreground[0]},
    background = { set = true, value = ansi.background[0]},
    modes = {
      bold =      { set = true, value = false }, 
      italic =    { set = true, value = false },
      underline = { set = true, value = false }
    },
  }
end

function styles.to_style(ansi_sequence)
  local codes = {}
  for code in ansi_sequence:gmatch('[0-9]+') do
    table.insert(codes, tonumber(code))
  end

  if #codes == 1 and codes[1] == 0 then
    return styles.reset();
  end

  local style = styles.none()
  for _,code in ipairs(codes) do
    if ansi.modes[code] then
      style.modes[ansi.modes[code]] = { set = true, value = true }
    elseif ansi.foreground[code] then
      style.foreground = { set = true, value = ansi.foreground[code] }
    elseif ansi.background[code] then
      style.background = { set = true, value = ansi.background[code] }
    end
  end

  return style
end

function styles.name(prefix, style)
  local style_name = prefix .. '_'
  for mode, value in pairs(style.modes) do
    if value.set and value.value then
      style_name = style_name .. mode:sub(1,1)
    end
  end

 return style_name .. '_' 
   .. style.foreground.value.cterm
   .. '_' 
   .. style.background.value.cterm
end

function styles.attributes(style) 
  local attributes = {} 

  local modes = {}
  for mode, value in pairs(style.modes) do
    if value.set and value.value then
      table.insert(modes, mode)
    end
  end

  if #modes > 0 then
    attributes.cterm = modes
  end

  if style.foreground.set then 
    attributes.ctermfg = style.foreground.value.cterm
    attributes.guifg = style.foreground.value.gui
  end

  if style.background.set then 
    attributes.ctermbg = style.background.value.cterm
    attributes.guibg = style.background.value.gui
  end

  return attributes
end

return styles
