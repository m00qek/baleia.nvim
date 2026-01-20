local locations = require("baleia.locations")

describe("[merge_neighbours]", function()
  it("Two codes,in the **same** line, without text between them", function()
    local locs = locations.extract({ strip_ansi_codes = true }, {}, { "\x1b[0m\x1b[31mfirst \x1b[0mline" })
    assert.combinators.match({
      {
        style = { offset = 9 },
        from = { line = 1, column = 1 },
        to = { line = 1, column = 6 },
      },
      {
        style = { offset = 4 },
        from = { line = 1, column = 7 },
        to = { line = 1, column = 10 },
      },
    }, locs)
  end)

  it("Two codes,in **different** line, without text between them", function()
    local locs = locations.extract(
      { strip_ansi_codes = true },
      {},
      { "first line\x1b[1m", "\x1b[31msecond \x1b[0mline" }
    )
    assert.combinators.match({
      {
        style = { offset = 5 },
        from = { line = 1, column = 11 },
        to = { line = 2, column = 7 },
      },
      {
        style = { offset = 4 },
        from = { line = 2, column = 8 },
        to = { line = 2, column = 11 },
      },
    }, locs)
  end)
end)

describe("[extract]", function()
  it("with no sequences", function()
    assert.combinators.match({}, locations.extract({ strip_ansi_codes = true }, {}, { "no sequences" }))
  end)

  it("with sequence at the beginning of the line", function()
    local lines = { "\x1b[0mfirst line" }
    assert.combinators.match({
      { from = { line = 1, column = 1 }, to = { line = 1 } },
    }, locations.extract({ strip_ansi_codes = true }, {}, lines))
  end)

  it("with sequence at the end of the line", function()
    local lines = { "first line\x1b[0m" }
    assert.combinators.match({
      { from = { line = 1, column = 11 }, to = { line = 1 } },
    }, locations.extract({ strip_ansi_codes = true }, {}, lines))
  end)

  it("with sequence at the beginning and end of the line", function()
    local lines = { "first line\x1b[0m", "\x1b[0msecond line" }
    assert.combinators.match({
      { from = { line = 1, column = 11 }, to = { line = 2 } },
    }, locations.extract({ strip_ansi_codes = true }, {}, lines))
  end)

  it("with blank line between", function()
    local lines = { "first line\x1b[0m", "second line", "third \x1b[0mline" }
    assert.combinators.match({
      { from = { line = 1, column = 11 }, to = { line = 3, column = 6 } },
      { from = { line = 3, column = 7 }, to = { line = 3, column = 10 } },
    }, locations.extract({ strip_ansi_codes = true }, {}, lines))
  end)

  it("with blank lines at the end", function()
    local lines = { "first \x1b[31mline", "second \x1b[32mline\x1b[0m", "third line" }

    assert.combinators.match({
      { from = { line = 1, column = 7 }, to = { line = 2, column = 7 } },
      { from = { line = 2, column = 8 }, to = { line = 2, column = 11 } },
      { from = { line = 2, column = 12 }, to = { line = 3 } },
    }, locations.extract({ strip_ansi_codes = true }, {}, lines))
  end)

  it("Two separated codes on the same line", function()
    local lines = { "A \x1b[31m B \x1b[32m C" }
    -- Code 1 at 3 (len 5). Text "A " (2 chars).
    -- Code 2 at 10 (len 5). Text " B " (3 chars).
    -- Original: A  [31m  B  [32m  C
    -- Stripped: A  B  C
    -- "A " (0-2).
    -- Code1 (2-7).
    -- " B " (7-10).
    -- Code2 (10-15).
    -- " C" (15+).
    
    -- Loc 1 (Red): Covers " B ".
    -- From: 3 (1-based index of code).
    -- After strip: 
    -- "A " is 1,2. Code is stripped.
    -- " B " starts at 3.
    -- So Loc 1 from = 3.
    
    -- Loc 2 (Green): Covers " C".
    -- Original From: 10.
    -- Shift: Code 1 (5) removed.
    -- From = 10 - 5 = 5.
    -- "A " (1,2), " B " (3,4,5). " C" starts at 6?
    -- A(1) space(2) B(3) space(4) C(5).
    -- Wait, " B " is 3 chars. space, B, space.
    -- 3, 4, 5.
    -- So " C" starts at 6.
    -- So Loc 2 from = 6.
    
    assert.combinators.match({
      { from = { line = 1, column = 3 }, to = { line = 1, column = 5 } }, -- Red covers " B "
      { from = { line = 1, column = 6 }, to = { line = 1, column = 7 } }, -- Green covers " C"
    }, locations.extract({ strip_ansi_codes = true }, {}, lines))
  end)
end)

local offsets = require("baleia.locations.offsets")
describe("[with_offset]", function()
  it("considers global offsets", function()
    local offset = { global = { line = 100, column = 10 } }
    local location = {
      {
        style = { offset = 0 },
        from = { line = 1, column = 1 },
        to = { line = 2, column = 1 },
      },
    }

    assert.combinators.match({
      {
        from = { line = 101, column = 11 },
        to = { line = 102, column = 11 },
      },
    }, offsets.apply(offset, location))
  end)

  it("considers line offsets", function()
    local offset = {
      global = { line = 0, column = 0 },
      lines = { [1] = { column = 5 } },
    }

    local location = {
      {
        style = { offset = 0 },
        from = { line = 1, column = 1 },
        to = { line = 2, column = 1 },
      },
    }

    assert.combinators.match({
      {
        from = { line = 1, column = 6 },
        to = { line = 2, column = 1 },
      },
    }, offsets.apply(offset, location))
  end)

  it("considers both global and line offsets", function()
    local offset = {
      global = { line = 100, column = 10 },
      lines = { [1] = { column = 5 } },
    }

    local location = {
      {
        style = { offset = 0 },
        from = { line = 1, column = 1 },
        to = { line = 2, column = 1 },
      },
    }

    assert.combinators.match({
      {
        from = { line = 1, column = 6 },
        to = { line = 102, column = 11 },
      },
    }, offsets.apply(offset, location))
  end)
end)
