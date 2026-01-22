local text = require("baleia.text")

describe("[strip_color_codes]", function()
  it("strip", function()
    local lines = { "first \x1b[31mline", "second \x1b[32mline\x1b[0m", "third line" }
    assert.combinators.match(
      { "first line", "second line", "third line" },
      text.content({ strip_ansi_codes = true }, lines)
    )
  end)
  it("with empty lines", function()
    assert.combinators.match({}, text.content({}, {}))
  end)
end)
