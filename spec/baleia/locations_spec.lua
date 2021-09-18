local locations = require("baleia.locations")

describe("[extract]", function()
   it("with no sequences", function()
      assert.combinators.match({}, locations.extract({ "no sequences" }))
   end)

   it("with sequence at the beginning of the line", function()
      local lines = { "\x1b[0mfirst line" }
      assert.combinators.match({
         { from = { line = 1, column = 1 }, to = { line = 1 } }
      }, locations.extract(lines))
   end)

   it("with sequence at the end of the line", function()
      local lines = { "first line\x1b[0m" }
      assert.combinators.match({
         { from = { line = 1, column = 11 }, to = { line = 1 } }
      }, locations.extract(lines))
   end)

   it("with sequence at the beggining and end of the line", function()
      local lines = { "first line\x1b[0m", "\x1b[0msecond line" }
      assert.combinators.match({
         { from = { line = 2, column = 1  }, to = { line = 2 } },
         { from = { line = 1, column = 11 }, to = { line = 1 } },
      }, locations.extract(lines))
   end)

   it("with blank line between", function()
      local lines = { "first line\x1b[0m", "second line", "third \x1b[0mline" }
      assert.combinators.match({
         { from = { line = 3, column = 7  }, to = { line = 3 } },
         { from = { line = 1, column = 11 }, to = { line = 3 } },
      }, locations.extract(lines))
   end)

   it("with blank lines at the end", function()
      local lines = { "first \x1b[31mline", "second \x1b[32mline\x1b[0m", "third line" }

      assert.combinators.match({
         { from = { line = 2, column = 17 }, to = { line = 3 } },
         { from = { line = 2, column = 8  }, to = { line = 2, column = 16 } },
         { from = { line = 1, column = 7  }, to = { line = 2, column =  7 } },
      }, locations.extract(lines))
   end)
end)

describe("[with_offset]", function()
   --it("considers ansi sequence lenght", function()
   --   local location = {
   --      style = { offset = 4 },
   --      from = { line = 1, column = 1 },
   --      to   = { line = 2, column = 1 },
   --   }

   --   assert.combinators.match({
   --      from = { line = 1, column = 5 },
   --      to   = { line = 2, column = 1 },
   --   }, locations.with_offset({ line = 0, column = 0 }, location))
   --end)

   it("considers offset parameter", function()
      local location = {
         {
            style = { offset = 0 },
            from = { line = 1, column = 1 },
            to   = { line = 2, column = 1 },
         },
      }

      assert.combinators.match({
         {
            from = { line = 101, column = 11 },
            to   = { line = 102, column = 11 },
         },
      }, locations.with_offset({ global = { line = 100, column = 10 } }, location))
   end)

   --it("considers both ansi_sequence length and offset parameter", function()
   --   local location = {
   --      style = { offset = 4 },
   --      from = { line = 1, column = 1 },
   --      to   = { line = 2, column = 1 },
   --   }

   --   assert.combinators.match({
   --      from = { line = 101, column = 15 },
   --      to   = { line = 102, column = 11 },
   --   }, locations.with_offset({ line = 100, column = 10 }, location))
   --end)
end)


describe("[strip]", function()
   it("", function()
      local locs = {
         { style = { offset = 4 }, from = { line = 2, column = 17 }, to = { line = 3 } },
         { style = { offset = 5 }, from = { line = 2, column =  8 }, to = { line = 2, column = 16 } },
         { style = { offset = 5 }, from = { line = 1, column =  7 }, to = { line = 2, column =  7 } },
      }
      assert.combinators.match({
         { from = { line = 2, column = 12 }, to = { line = 3 } },
         { from = { line = 2, column =  8 }, to = { line = 2, column = 11 } },
         { from = { line = 1, column =  7 }, to = { line = 2, column =  7 } },
      }, locations.strip(locs))
   end)
end)
