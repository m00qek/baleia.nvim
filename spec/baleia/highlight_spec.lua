local highlight = require("baleia.highlight")

describe("[all]", function()
   it("", function()
      local lines = { "; first line\x1b[32m ", "; \x1b[31msecond line" }

      assert.combinators.match(
         { highlights = {
             { line = 1, firstcolumn = 18, name = "B_green_none" },
             { line = 2, firstcolumn = 8,  name = "B_red_none" } },
           definitions = {
             B_red_none   = { guifg = "red",   ctermfg = "red" },
             B_green_none = { guifg = "green", ctermfg = "green" },
           },
         },
         highlight.all({ name = 'B', line_starts_at = 3, colors = { cterm = { }, gui = { } } },
                       { global = { column = 0, line = 0 } },
                       lines))
   end)
end)
