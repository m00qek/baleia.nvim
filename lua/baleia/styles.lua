local ansi = require("baleia.ansi")

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
      offset = to.offset or from.offset,
      modes = { },
   }

   for _, mode in pairs(ansi.modes) do
      style.modes[mode] = merge_value(from.modes[mode], to.modes[mode])
   end

   return style
end

function styles.none()
   local style = {
      foreground = { set = false, value = ansi.foreground[0]},
      background = { set = false, value = ansi.background[0]},
      modes = { },
   }

   for _, mode in pairs(ansi.modes) do
      style.modes[mode] = { set = false, value = false }
   end

   return style
end

function styles.reset(offset)
   local style = {
      foreground = { set = true, value = ansi.foreground[0]},
      background = { set = true, value = ansi.background[0]},
      modes = { },
      offset = offset,
   }

   for _, mode in pairs(ansi.modes) do
      style.modes[mode] = { set = true, value = false }
   end

   return style
end

function styles.to_style(ansi_sequence)
   local codes = {}
   for code in ansi_sequence:gmatch("[0-9]+") do
      table.insert(codes, tonumber(code))
   end

   if #codes == 1 and codes[1] == 0 then
      return styles.reset(#ansi_sequence);
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

   style.offset = #ansi_sequence
   return style
end

function styles.name(prefix, style)
   local modes = { }
   for mode, value in pairs(style.modes) do
      if value.set and value.value then
         table.insert(modes, mode:sub(1,1):upper())
      end
   end

   local name = prefix
   if #modes > 0 then
      table.sort(modes)
      name = name .. "_" .. table.concat(modes)
   end

   return name .. "_" .. style.foreground.value .. "_" .. style.background.value
end

function styles.attributes(style, colors)
  local attributes = {}

  local modes = {}
  for mode, value in pairs(style.modes) do
    if value.set and value.value then
      table.insert(modes, mode)
    end
  end

  if #modes > 0 then
    table.sort(modes)
    attributes.cterm = modes
  end

  if style.foreground.set then
    local value = style.foreground.value
    attributes.ctermfg = colors.cterm[value] or value
    attributes.guifg = colors.gui[value] or value
  end

  if style.background.set then
    local value = style.background.value
    attributes.ctermbg = colors.cterm[value] or value
    attributes.guibg = colors.gui[value] or value
  end

  return attributes
end

return styles
