local ansi = require("baleia.ansi")

describe("baleia.ansi", function()
  local function apply(sequence, base)
    local style = base or {}
    ansi.apply(sequence, style)
    return style
  end

  describe("Basic Attribute Toggling", function()
    it("toggles bold", function()
      assert.combinators.match({ bold = true }, apply("1"))
      assert.combinators.match({ bold = nil }, apply("22", { bold = true }))
    end)

    it("toggles italic", function()
      assert.combinators.match({ italic = true }, apply("3"))
      assert.combinators.match({ italic = nil }, apply("23", { italic = true }))
    end)

    it("toggles underline", function()
      assert.combinators.match({ underline = true }, apply("4"))
      assert.combinators.match({ underline = nil }, apply("24", { underline = true }))
    end)

    it("toggles strikethrough", function()
      assert.combinators.match({ strikethrough = true }, apply("9"))
      assert.combinators.match({ strikethrough = nil }, apply("29", { strikethrough = true }))
    end)

    it("toggles reverse", function()
      assert.combinators.match({ reverse = true }, apply("7"))
      assert.combinators.match({ reverse = nil }, apply("27", { reverse = true }))
    end)
  end)

  describe("Standard Colors (4-bit)", function()
    it("sets foreground colors (30-37)", function()
      assert.combinators.match({ ctermfg = 1 }, apply("31"))
      assert.combinators.match({ ctermfg = 4 }, apply("34"))
    end)

    it("sets background colors (40-47)", function()
      assert.combinators.match({ ctermbg = 2 }, apply("42"))
      assert.combinators.match({ ctermbg = 6 }, apply("46"))
    end)

    it("sets bright foreground colors (90-97)", function()
      assert.combinators.match({ ctermfg = 8 }, apply("90"))
      assert.combinators.match({ ctermfg = 15 }, apply("97"))
    end)

    it("sets bright background colors (100-107)", function()
      assert.combinators.match({ ctermbg = 8 }, apply("100"))
      assert.combinators.match({ ctermbg = 15 }, apply("107"))
    end)

    it("resets colors", function()
      assert.combinators.match(
        { ctermfg = nil, foreground = nil },
        apply("39", { ctermfg = 1, foreground = "#ff0000" })
      )
      assert.combinators.match(
        { ctermbg = nil, background = nil },
        apply("49", { ctermbg = 1, background = "#ff0000" })
      )
    end)
  end)

  describe("Extended Colors (8-bit / 256-color)", function()
    it("sets xterm foreground", function()
      assert.combinators.match({ ctermfg = 200 }, apply("38;5;200"))
    end)

    it("sets xterm background", function()
      assert.combinators.match({ ctermbg = 15 }, apply("48;5;15"))
    end)

    it("sets xterm underline color", function()
      assert.combinators.match({ ctermsp = 10 }, apply("58;5;10"))
    end)

    it("handles missing arguments gracefully", function()
      local style = apply("38;5")
      assert.combinators.match({ ctermfg = nil }, style)
    end)
  end)

  describe("TrueColor (24-bit RGB)", function()
    it("sets rgb foreground", function()
      assert.combinators.match({ foreground = "#ff0000" }, apply("38;2;255;0;0"))
    end)

    it("sets rgb background", function()
      assert.combinators.match({ background = "#0000ff" }, apply("48;2;0;0;255"))
    end)

    it("sets rgb underline color", function()
      assert.combinators.match({ special = "#0a141e" }, apply("58;2;10;20;30"))
    end)
  end)

  describe("Complex Underline Styles", function()
    it("sets underline styles", function()
      assert.combinators.match({ undercurl = true }, apply("4:3"))
      assert.combinators.match({ underdouble = true }, apply("4:2"))
      assert.combinators.match({ underdotted = true }, apply("4:4"))
      assert.combinators.match({ underdashed = true }, apply("4:5"))
    end)

    it("resets extended underlines", function()
      local base = { undercurl = true, underdouble = true, underline = true }
      assert.combinators.match({
        undercurl = nil,
        underdouble = nil,
        underline = nil,
        underdotted = nil,
        underdashed = nil,
      }, apply("4:0", base))
    end)

    it("standard underline off clears all", function()
      local base = { undercurl = true, underdouble = true, underline = true }
      assert.combinators.match({
        undercurl = nil,
        underdouble = nil,
        underline = nil,
        underdotted = nil,
        underdashed = nil,
      }, apply("24", base))
    end)
  end)

  describe("Reset & Clear", function()
    it("clears everything with 0", function()
      local base = { bold = true, ctermfg = 1, ctermbg = 2, italic = true }
      assert.combinators.match({}, apply("0", base))
    end)

    it("clears everything with empty sequence (implicit 0 behavior often seen or just check specific)", function()
      local base = { bold = true }
      assert.combinators.match({}, apply("", base))
    end)
  end)

  describe("Complex / Chained Sequences", function()
    it("handles mixed attributes", function()
      assert.combinators.match({ bold = true, italic = true, underline = true }, apply("1;3;4"))
    end)

    it("handles attribute and color", function()
      assert.combinators.match({ bold = true, ctermfg = 1 }, apply("1;31"))
    end)

    it("handles reset mid-sequence", function()
      -- 1 sets bold, 0 resets all, 31 sets red. Result should be only red.
      assert.combinators.match({ ctermfg = 1, bold = nil }, apply("1;0;31"))
    end)

    it("handles xterm and attributes correctly", function()
      -- 38;5;200 consumes 200. 1 is next.
      assert.combinators.match({ ctermfg = 200, bold = true }, apply("38;5;200;1"))
    end)
  end)

  describe("State Preservation & Cloning", function()
    it("preserves state across calls", function()
      local s1 = {}
      apply("1", s1)
      assert.combinators.match({ bold = true }, s1)
      apply("31", s1)
      assert.combinators.match({ bold = true, ctermfg = 1 }, s1)
    end)

    it("clones correctly", function()
      local s1 = { bold = true, ctermfg = 1 }
      local s2 = ansi.clone(s1)
      assert.combinators.match(s1, s2)

      s1.italic = true
      assert.combinators.match({ bold = true, ctermfg = 1 }, s2)
      assert.combinators.match({ italic = true }, s1)
    end)
  end)

  describe("Edge Cases", function()
    it("ignores unknown codes", function()
      assert.combinators.match({ bold = true }, apply("1;999"))
    end)
  end)
end)
