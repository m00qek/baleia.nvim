local xterm = require("baleia.xterm")

describe("baleia.xterm", function()
  describe("from_rgb", function()
    it("maps pure black to colour 16 (not 231)", function()
      -- colour 16 is #000000 in the 6x6x6 cube; 231 is #ffffff.
      -- A negative grey index was computed for average < 3, giving grey_code=231,
      -- but the cube distance wins in practice. This test pins the correct result.
      assert.equals(16, xterm.from_rgb(0, 0, 0))
    end)

    it("maps near-black colours correctly", function()
      -- average = 1, old code produced grey = -2 and grey_code = 231
      assert.equals(16, xterm.from_rgb(1, 1, 1))
    end)

    it("maps pure white to colour 231", function()
      assert.equals(231, xterm.from_rgb(255, 255, 255))
    end)

    it("maps a bright red to colour 196", function()
      assert.equals(196, xterm.from_rgb(255, 0, 0))
    end)

    it("maps a mid-grey to a grey ramp entry", function()
      -- 128,128,128 should land in the grey ramp (232-255), not the cube
      local code = xterm.from_rgb(128, 128, 128)
      assert.truthy(code >= 232 and code <= 255, "expected grey ramp, got " .. tostring(code))
    end)
  end)
end)
