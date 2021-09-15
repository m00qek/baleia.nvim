local lines = require("baleia.lines")

local content = { "first", "second", "third", "fourth" }
local get_lines = function(_, line) return {unpack(content, line, #content)} end

describe("[lines]", function()
   it("[all]", function()
      assert.combinators.match(
         { first = 1, lines = { "first", "second", "third", "fourth" } },
         lines.all()(get_lines))
   end)

   it("[moving_window]", function()
      assert.combinators.match(
         { first = 3, lines = { "third", "fourth" } },
         lines.moving_window(2)(get_lines, nil, 1, 4))
   end)

   it("[take_while]", function()
      local predicate = function(line) return line ~= "first" end
      assert.combinators.match(
         { first = 2, lines = { "second", "third", "fourth" } },
         lines.take_while(predicate)(get_lines, nil, 1, 4))
   end)
end)
