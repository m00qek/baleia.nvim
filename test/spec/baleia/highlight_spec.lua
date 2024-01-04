local text = require("baleia.text")

describe("[all]", function()
  it("", function()
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
end)
