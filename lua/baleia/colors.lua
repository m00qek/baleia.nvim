local xterm = require('baleia.colors.xterm')

local colors = {}

colors.from_xterm = function(code)
  return {
    set = true,
    value = {
      name = code,
      cterm = code,
      inferred = {
        gui = code ~= 'none' and xterm.to_truecolor(code) or code,
      }
    }
  }
end

colors.from_truecolor = function(red, green, blue)
  local hexcode = string.format('%02x%02x%02x', red or 0, green or 0, blue or 0)
  return {
    set = true,
    value = {
      name = hexcode,
      cterm = xterm.from_rgb(red, green, blue),
      gui = '#' .. hexcode,
    }
  }
end

return colors
