local text = require("baleia.text")

describe("[all]", function()
  it("basic single line highlights", function()
    local lines = { "; first line\x1b[32m ", "; \x1b[31msecond line" }

    local marks, highlights = text.colors(
      { strip_ansi_codes = true, name = "B", line_starts_at = 3, colors = { cterm = {}, gui = {} } },
      lines,
      { global = { column = 1, line = 0 } }
    )

    assert.combinators.match({
      { line = 1, firstcolumn = 14, highlight = "B_0_2_none_none" },
      { line = 2, firstcolumn = 4, highlight = "B_0_1_none_none" },
    }, marks)

    assert.combinators.match({
      B_0_1_none_none = { foreground = "#800000", ctermfg = 1 },
      B_0_2_none_none = { foreground = "#008000", ctermfg = 2 },
    }, highlights)
  end)

  it("multi-line highlights", function()
    local lines = { "\x1b[32mstart", "middle", "end\x1b[0m" }

    local marks, _ = text.colors(
      { strip_ansi_codes = true, name = "B", line_starts_at = 1, colors = { cterm = {}, gui = {} } },
      lines,
      { global = { column = 0, line = 0 } }
    )

    -- Should produce 3 marks: one for each line
    assert.combinators.match({
      { line = 1, firstcolumn = 1, highlight = "B_0_2_none_none" }, -- start
      { line = 2, firstcolumn = 1, highlight = "B_0_2_none_none" }, -- middle
      { line = 3, firstcolumn = 1, lastcolumn = 3, highlight = "B_0_2_none_none" }, -- end
    }, marks)
  end)

  it("multi-line highlights with custom line_starts_at", function()
    local lines = { "\x1b[32mstart", "middle", "end\x1b[0m" }

    local marks, _ = text.colors(
      { strip_ansi_codes = true, name = "B", line_starts_at = 5, colors = { cterm = {}, gui = {} } },
      lines,
      { global = { column = 0, line = 0 } }
    )

    -- Line 3 is skipped because line_starts_at (5) > lastcolumn (3)
    assert.combinators.match({
      { line = 1, firstcolumn = 1, highlight = "B_0_2_none_none" }, -- start
      { line = 2, firstcolumn = 5, highlight = "B_0_2_none_none" }, -- middle (starts at 5)
    }, marks)
  end)
  
  it("highlight ending at exact line end", function()
    local lines = { "text\x1b[31m colored\x1b[0m" }
    local marks, _ = text.colors(
      { strip_ansi_codes = true, name = "B", line_starts_at = 1, colors = { cterm = {}, gui = {} } },
      lines,
      { global = { column = 0, line = 0 } }
    )
    
     assert.combinators.match({
      { line = 1, firstcolumn = 5, lastcolumn = 12, highlight = "B_0_1_none_none" },
    }, marks)
  end)

end)

