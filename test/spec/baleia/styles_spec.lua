local styles = require('baleia.styles')

describe("[name]", function()
   it("when it is none()", function()
      local style = styles.none()
      assert.combinators.match("Baleia_0_none_none_none",
         styles.name("Baleia", style))
   end)

   it("when it is reset()", function()
      local style = styles.reset(1)
      assert.combinators.match("Baleia_598_none_none_none",
         styles.name("Baleia", style))
   end)

   it("with only foreground and background", function()
      local style = styles.none()

      style.background = { set = true, value = { name = 'green' } }
      style.foreground = { set = true, value = { name = 'blue' } }

      assert.combinators.match("Baleia_0_blue_green_none",
         styles.name("Baleia", style))
   end)

   it("with background, foreground and modifiers", function()
      local style = styles.none()

      style.background = { set = true, value = { name = 'green' } }
      style.foreground = { set = true, value = { name = 'blue' } }
      style.modes.italic = { set = true, value = true, name = 2^0 }
      style.modes.bold = { set = true, value = true, name = 2^1 }

      assert.combinators.match("Baleia_3_blue_green_none",
         styles.name("Baleia", style))
   end)
end)

describe("[attributes]", function()
   local colors = { cterm = { }, gui = { } }

   it("when it is none()", function()
      local style = styles.none()
      assert.combinators.match({ }, styles.attributes(style, colors))
   end)

   it("when it is reset()", function()
      local style = styles.reset(1)
      assert.combinators.match({
         foreground = "none",
         background = "none",
         ctermbg = "none",
         ctermfg = "none",
      }, styles.attributes(style, colors))
   end)

   it("with modes", function()
      local style = styles.none()

      style.modes.italic = { set = true, value = true }
      style.modes.bold = { set = true, value = true }

      assert.combinators.match({
         italic = true,
         bold = true,
      }, styles.attributes(style, colors))
   end)

   it("with modes, background and foreground", function()
      local style = styles.none()
      style.background = { set = true, value = { inferred = { gui = "#008000" }, name = 2, cterm = 2 } }
      style.foreground = { set = true, value = { inferred = { gui = "#000080" }, name = 4, cterm = 4 } }
      style.modes.bold = { set = true, value = true }

      assert.combinators.match({
         background = "#008000",
         foreground = "#000080",
         ctermbg = 2,
         ctermfg = 4,
         bold = true,
      }, styles.attributes(style, colors))
   end)

   it("with background and foreground, overriding colors", function()
      local style = styles.none()

      style.background = { set = true, value = { inferred = { gui = "#008000" }, name = 2, cterm = 2 } }
      style.foreground = { set = true, value = { inferred = { gui = "#000080" }, name = 4, cterm = 4 } }

      assert.combinators.match({
         background = "#008000",
         foreground = "#000080",
         ctermbg = 2,
         ctermfg = 4,
      }, styles.attributes(style, colors))
   end)

   it("with background and foreground", function()
      local style = styles.none()
      local custom_colors = {
         [2] = "#123ABC",
         [4] = "#fa8bf9",
      }

      style.background = { set = true, value = { inferred = { gui = "#008000" }, name = 2, cterm = 2 } }
      style.foreground = { set = true, value = { inferred = { gui = "#000080" }, name = 4, cterm = 4 } }

      assert.combinators.match({
         background = "#123ABC",
         foreground = "#fa8bf9",
         ctermbg = 2,
         ctermfg = 4,
      }, styles.attributes(style, custom_colors))
   end)
end)

describe("[reset]", function()
   it("must set everything to default value", function()
      local style = styles.reset(1)

      assert.combinators.match({
         foreground = { set = true, value = { gui = "none", name = "none", cterm = "none" } },
         background = { set = true, value = { gui = "none", name = "none", cterm = "none" } },
      }, style)

      for _, value in pairs(style.modes) do
         assert.combinators.match({ set = true, value = false }, value)
      end

   end)
end)

describe("[none]", function()
   it("should not set anything", function()
      local style = styles.none()

      assert.combinators.match({
         foreground = { set = false },
         background = { set = false },
      }, style)

      for _, value in pairs(style.modes) do
         assert.combinators.match({ set = false }, value)
      end
   end)
end)

describe("[to_style]", function()
   it("ignores unknown codes", function()
      assert.combinators.match(styles.none(), styles.to_style("\x1b[99m"))
   end)

   it("extract reset code", function()
      assert.combinators.match(styles.reset(4), styles.to_style("\x1b[0m"))
   end)

   it("extract background", function()
      assert.combinators.match({
         background = { set = true, value = { inferred = { gui = "#800000" }, name = 1, cterm = 1 } }
      }, styles.to_style("\x1b[41m"))
   end)

   it("extract foreground", function()
      assert.combinators.match({
         foreground = { set = true, value = { inferred = { gui = "#800000" }, name = 1, cterm = 1 } }
      }, styles.to_style("\x1b[31m"))
   end)

   it("extract modifier", function()
      assert.combinators.match({
         modes = { bold = { set = true, value = true, name = 2^1 } }
      }, styles.to_style("\x1b[1m"))
   end)

   it("extract offset", function()
      assert.combinators.match({ offset = 4 }, styles.to_style("\x1b[1m"))
   end)

   it("extract multiple attributes", function()
      assert.combinators.match({
         background = { set = true, value = { inferred = { gui = "#800000" }, name = 1, cterm = 1 } },
         foreground = { set = true, value = { inferred = { gui = "#800000" }, name = 1, cterm = 1 } },
         modes = { bold  = { set = true, value = true } }
      }, styles.to_style("\x1b[1;31;41m"))
   end)
end)

describe("[merge]", function()
   it("merging with none always returns the original style", function()
      assert.combinators.match(
         styles.reset(4),
         styles.merge(styles.reset(4), styles.none()))

      assert.combinators.match(
         styles.to_style("\x1b[31m"),
         styles.merge(styles.to_style("\x1b[31m"), styles.none()))
   end)
   it("merging with reset always returns reset", function()
      assert.combinators.match(
         styles.reset(4),
         styles.merge(styles.none(), styles.reset(4)))

      assert.combinators.match(
         styles.reset(4),
         styles.merge(styles.to_style("\x1b[31m"), styles.reset(4)))
   end)

   it("merging two different styles", function()
      local style1 = styles.none()
      style1.background = { set = true, value = "red" }
      style1.modes.bold = { set = true, value = true }

      local style2 = styles.none()
      style1.foreground = { set = true, value = "green" }
      style1.modes.bold = { set = true, value = false }

      assert.combinators.match({
         background = { set = true, value = "red" },
         foreground = { set = true, value = "green" },
         modes = { bold = { set = true, value = false } }
      }, styles.merge(style1, style2))
   end)
end)
