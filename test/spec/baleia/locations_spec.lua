local locations = require("baleia.locations")

describe("[merge_neighbours]", function()
   it("Two codes,in the **same** line, without text between them", function()
      local locs = locations.extract({ "\x1b[0m\x1b[31mfirst line" })
      assert.combinators.match({
         {
            style = { offset  = 9 },
            from  = { line = 1, column = 1 },
            to    = { line = 1 }
         }
      }, locations.merge_neighbours(locs))
   end)

   it("Two codes,in **different** line, without text between them", function()
      local locs = locations.extract({ "first line\x1b[1m", "\x1b[31msecond line" })
      assert.combinators.match({
         {
            style = { offset  = 5 },
            from  = { line = 1, column = 11 },
            to    = { line = 2 }
         },
      }, locations.merge_neighbours(locs))
   end)

end)

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

   it("with sequence at the beginning and end of the line", function()
      local lines = { "first line\x1b[0m", "\x1b[0msecond line" }
      assert.combinators.match({
         { from = { line = 1, column = 11 }, to = { line = 1 } },
         { from = { line = 2, column = 1 }, to = { line = 2 } },
      }, locations.extract(lines))
   end)

   it("with blank line between", function()
      local lines = { "first line\x1b[0m", "second line", "third \x1b[0mline" }
      assert.combinators.match({
         { from = { line = 1, column = 11 }, to = { line = 3 } },
         { from = { line = 3, column = 7  }, to = { line = 3 } },
      }, locations.extract(lines))
   end)

   it("with blank lines at the end", function()
      local lines = { "first \x1b[31mline", "second \x1b[32mline\x1b[0m", "third line" }

      assert.combinators.match({
         { from = { line = 1, column = 7  }, to = { line = 2, column =  7 } },
         { from = { line = 2, column = 8  }, to = { line = 2, column = 16 } },
         { from = { line = 2, column = 17 }, to = { line = 3 } },
      }, locations.extract(lines))
   end)
end)

describe("[with_offset]", function()
   it("considers global offsets", function()
      local offset = { global = { line = 100, column = 10 } }
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
      }, locations.with_offset(offset, location))
   end)

   it("considers line offsets", function()
      local offset = {
         global = { line = 0, column = 0 },
         line = { [1] = { column = 5 } }
      }

      local location = {
         {
            style = { offset = 0 },
            from = { line = 1, column = 1 },
            to   = { line = 2, column = 1 },
         },
      }

      assert.combinators.match({
         {
            from = { line = 1, column = 6 },
            to   = { line = 2, column = 1 },
         },
      }, locations.with_offset(offset, location))
   end)

   it("considers both global and line offsets", function()
      local offset = {
         global = { line = 100, column = 10 },
         line = { [1] = { column = 5 } }
      }

      local location = {
         {
            style = { offset = 0 },
            from = { line = 1, column = 1 },
            to   = { line = 2, column = 1 },
         },
      }

      assert.combinators.match({
         {
            from = { line = 101, column = 16 },
            to   = { line = 102, column = 11 },
         },
      }, locations.with_offset(offset, location))
   end)
end)

describe("[strip_ansi_codes]", function()
   it("", function()
      local locs = {
         { style = { offset = 5 }, from = { line = 1, column =  7 }, to = { line = 2, column =  7 } },
         { style = { offset = 5 }, from = { line = 2, column =  8 }, to = { line = 2, column = 16 } },
         { style = { offset = 4 }, from = { line = 2, column = 17 }, to = { line = 3 } },
      }
      assert.combinators.match({
         { from = { column =  7 }, to = { column =  7 } },
         { from = { column =  8 }, to = { column = 11 } },
         { from = { column = 12 } },
      }, locations.strip_ansi_codes(locs))
   end)
end)

describe("[ignore_ansi_codes]", function()
   it("", function()
      local locs = {
         { style = { offset = 5 }, from = { line = 1, column =  7 }, to = { line = 2, column =  7 } },
         { style = { offset = 5 }, from = { line = 2, column =  8 }, to = { line = 2, column = 16 } },
         { style = { offset = 4 }, from = { line = 2, column = 17 }, to = { line = 3 } },
      }
      assert.combinators.match({
         { from = { column = 12 }, to = { column =  7 } },
         { from = { column = 13 }, to = { column = 16 } },
         { from = { column = 21 } },
      }, locations.ignore_ansi_codes(locs))
   end)
end)
