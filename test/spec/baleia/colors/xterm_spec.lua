local xterm = require('baleia.colors.xterm')

local function hex2rgb(hex)
   hex = hex:gsub("#","")
   return
      tonumber("0x"..hex:sub(1,2)),
      tonumber("0x"..hex:sub(3,4)),
      tonumber("0x"..hex:sub(5,6))
end

describe("[from_rgb]", function()
   it("conversion works in both directions", function()
      for code = 16, 255 do
         local red, green, blue = hex2rgb(xterm.to_truecolor(code))
         assert.are.equals(code, xterm.from_rgb(red, green, blue))
      end
   end)
end)
