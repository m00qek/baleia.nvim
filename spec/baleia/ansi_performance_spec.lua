local ansi = require("baleia.ansi")

describe("baleia.lexer performance (cloning)", function()
  it("generates zero garbage when parsing ANSI codes (closure allocation check)", function()
    local input = "\27[41;3;38;5;128m" -- A standard color code
    local style = {}

    -- warm up the JIT and force a full GC sweep
    for _ = 1, 100 do
      ansi.apply(input, style)
    end
    collectgarbage("collect")

    -- measure memory before the loop
    local before = collectgarbage("count")

    -- hammer the function (10,000 iterations)
    for _ = 1, 10000 do
      ansi.apply(input, style)
    end

    -- measure memory after (without collecting)
    local after = collectgarbage("count")
    local delta = after - before

    assert.is_true(
      delta < 9,
      string.format("\n[Memory Delta: %.4f KB] ansi.apply is allocating memory (likely creating closures)!", delta)
    )
  end)
end)
