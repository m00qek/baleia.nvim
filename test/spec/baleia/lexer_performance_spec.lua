local lexer = require("baleia.lexer")
local styles = require("baleia.styles")
local spy = require("luassert.spy")

describe("baleia.lexer performance (cloning)", function()
  local snapshot

  before_each(function()
    snapshot = spy.on(styles, "clone")
  end)

  after_each(function()
    snapshot:revert()
  end)

  it("does not clone for plain text (no seed)", function()
    local lines = { "plain text" }
    lexer.lex(lines, true, 0)

    assert.spy(snapshot).was_called(0)
  end)

  it("clones exactly once for a single colored span", function()
    -- \27[31m -> Red
    local lines = { "\27[31mred text" }
    lexer.lex(lines, true, 0)

    assert.spy(snapshot).was_called(1)
  end)

  it("merges consecutive codes with a single clone", function()
    -- \27[31m (Red) + \27[1m (Bold) -> "bold red"
    -- Should NOT clone for the intermediate Red state
    local lines = { "\27[31m\27[1mbold red" }
    lexer.lex(lines, true, 0)

    assert.spy(snapshot).was_called(1)
  end)

  it("clones for each distinct text span", function()
    -- Red -> "Red" (Clone 1)
    -- Green -> "Green" (Clone 2)
    local lines = { "\27[31mRed\27[32mGreen" }
    lexer.lex(lines, true, 0)

    assert.spy(snapshot).was_called(2)
  end)

  it("clones the seed style once at initialization", function()
    local seed = { ctermfg = 1 }
    local lines = { "plain text" }
    lexer.lex(lines, true, 0, seed)

    -- 1 clone for seed initialization
    -- 0 clones for highlights (since text just continues the seed state, but we only clone ON highlight insertion)
    -- Wait, if we have a seed, "plain text" IS a highlight because `is_active(state)` is true.
    -- So it should be 1 (seed) + 1 (highlight) = 2.
    
    assert.spy(snapshot).was_called(2)
  end)
  
  it("clones for text following a code, even if not changing visual state (edge case)", function()
     -- \27[31mRed\27[31mRed again
     -- Red -> "Red" (Clone 1)
     -- Red -> "Red again" (Clone 2) - we don't optimize out redundant codes that split text
     local lines = { "\27[31mRed\27[31mRed again" }
     lexer.lex(lines, true, 0)
     
     assert.spy(snapshot).was_called(2)
  end)

  it("merges codes across lines with a single clone", function()
    -- Line 1: Red code
    -- Line 2: Bold code + "Text"
    -- Should only clone once for "Text" (Red+Bold)
    local lines = { "\27[31m", "\27[1mtext" }
    lexer.lex(lines, true, 0)

    assert.spy(snapshot).was_called(1)
  end)
end)
