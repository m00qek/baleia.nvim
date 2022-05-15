local text = require('baleia.text')

describe("[strip_color_codes]", function()

  it("strip", function()
    local lines = { "first \x1b[31mline", "second \x1b[32mline\x1b[0m", "third line" }
    assert.combinators.match(
      { "first line", "second line", "third line" },
      text.strip_color_codes(lines))
  end)
  it("with empty lines", function()
    assert.combinators.match({ }, text.strip_color_codes({ }))
  end)
end)

describe("[lastcolumn]", function()
  it("calculate last column", function()
    local lines = { "first line", "second line" }
    assert.combinators.match(11, text.lastcolumn(lines))
  end)
end)
