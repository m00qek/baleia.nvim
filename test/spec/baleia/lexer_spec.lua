local lexer = require("baleia.lexer")
local styles = require("baleia.styles")

describe("baleia.lexer", function()
  describe("code discovery & positioning", function()
    it("handles plain text with no codes", function()
      local lines = { "hello world" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "hello world",
          highlights = {},
        },
      }, result)
    end)

    it("handles code at the beginning", function()
      local lines = { "\27[31mred" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "red",
          highlights = {
            {
              from = 0,
              to = 2,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
          },
        },
      }, result)
    end)

    it("handles code in the middle", function()
      local lines = { "prefix \27[31mred" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "prefix red",
          highlights = {
            {
              from = 7,
              to = 9,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
          },
        },
      }, result)
    end)

    it("handles code at the end (changing state for nothing)", function()
      local lines = { "text\27[31m" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "text",
          highlights = {},
        },
      }, result)
    end)

    it("handles string with only codes", function()
      local lines = { "\27[31m\27[1m" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "",
          highlights = {},
        },
      }, result)
    end)

    it("handles codes at the end of input with no following text", function()
      local lines = { "some text", "\27[31m\27[1m" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "some text",
          highlights = {},
        },
        {
          text = "",
          highlights = {},
        },
      }, result)
    end)

    it("handles composite codes (semicolon separated)", function()
      -- \x1b[1;31m -> Bold + Red in one sequence
      local lines = { "\27[1;31mbold red" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "bold red",
          highlights = {
            {
              from = 0,
              to = 7,
              style = {
                foreground = { set = true, value = { name = 1 } },
                modes = { bold = { set = true, value = { enabled = true } } },
              },
            },
          },
        },
      }, result)
    end)

    it("handles complex codes (256 colors)", function()
      -- \x1b[38;5;208m -> Orange (256 color)
      local lines = { "\27[38;5;208mcolor 208" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "color 208",
          highlights = {
            {
              from = 0,
              to = 8,
              style = {
                foreground = { set = true, value = { name = 208 } },
              },
            },
          },
        },
      }, result)
    end)
  end)

  describe("state accumulation & coalescing", function()
    it("merges consecutive codes into a single highlight", function()
      -- Red (31) + Bold (1)
      local lines = { "\27[31m\27[1mbold red" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "bold red",
          highlights = {
            {
              from = 0,
              to = 7,
              style = {
                foreground = { set = true, value = { name = 1 } },
                modes = { bold = { set = true, value = { enabled = true } } },
              },
            },
          },
        },
      }, result)
    end)

    it("handles redundant codes without creating breaks", function()
      -- Red + Red + Text
      local lines = { "\27[31m\27[31mred" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "red",
          highlights = {
            {
              from = 0,
              to = 2,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
          },
        },
      }, result)
    end)
  end)

  describe("state transition & resetting", function()
    it("stops highlight on reset", function()
      local lines = { "\27[31mred\27[0m plain" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "red plain",
          highlights = {
            {
              from = 0,
              to = 2,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
            -- No highlight for " plain"
          },
        },
      }, result)
    end)

    it("switches styles correctly", function()
      local lines = { "\27[31mred\27[32mgreen" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "redgreen",
          highlights = {
            {
              from = 0,
              to = 2,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
            {
              from = 3,
              to = 7,
              style = { foreground = { set = true, value = { name = 2 } } },
            },
          },
        },
      }, result)
    end)

    it("Two separated codes on the same line", function()
      -- Input: "A \27[31m B \27[32m C"
      -- Stripped: "A  B  C"
      -- Indices:
      -- "A " -> 0, 1 (No highlight)
      -- " B " -> 2, 3, 4 (Red)
      -- " C" -> 5, 6 (Green)
      local lines = { "A \27[31m B \27[32m C" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "A  B  C",
          highlights = {
            {
              from = 2,
              to = 4,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
            {
              from = 5,
              to = 6,
              style = { foreground = { set = true, value = { name = 2 } } },
            },
          },
        },
      }, result)
    end)
  end)

  describe("text adjustment", function()
    it("returns stripped text and indices by default", function()
      local lines = { "A\27[31mB" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "AB",
          highlights = {
            {
              from = 1,
              to = 1,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
          },
        },
      }, result)
    end)

    it("returns raw text and adjusted indices when strip=false", function()
      local lines = { "A\27[31mB" }
      local result = lexer.lex(lines, false)

      assert.combinators.match({
        {
          text = "A\27[31mB",
          highlights = {
            {
              -- 'A' is 0
              -- '\27[31m' is 1..5
              -- 'B' is 6
              from = 6,
              to = 6,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
          },
        },
      }, result)
    end)
  end)

  describe("multi-line propagation", function()
    it("carries state to the next line", function()
      local lines = { "\27[31mred", "still red" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "red",
          highlights = {
            {
              style = { foreground = { set = true, value = { name = 1 } } },
            },
          },
        },
        {
          text = "still red",
          highlights = {
            {
              from = 0,
              to = 8,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
          },
        },
      }, result)
    end)

    it("resets state at the end of line affecting next line", function()
      local lines = { "\27[31mred\27[0m", "plain" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "red",
          highlights = {
            { style = { foreground = { set = true, value = { name = 1 } } } },
          },
        },
        {
          text = "plain",
          highlights = {},
        },
      }, result)
    end)

    it("merges split codes across lines", function()
      -- Line 1 ends with Red (31)
      -- Line 2 starts with Bold (1)
      -- Result: Line 2 text is Red + Bold
      local lines = { "line one\27[31m", "\27[1mline two" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "line one",
          highlights = {},
        },
        {
          text = "line two",
          highlights = {
            {
              from = 0,
              to = 7,
              style = {
                foreground = { set = true, value = { name = 1 } },
                modes = { bold = { set = true, value = { enabled = true } } },
              },
            },
          },
        },
      }, result)
    end)

    it("persists state across empty lines", function()
      local lines = { "\27[31mred", "", "still red" }
      local result = lexer.lex(lines)

      assert.combinators.match({
        {
          text = "red",
          highlights = {
            { style = { foreground = { set = true, value = { name = 1 } } } },
          },
        },
        {
          text = "",
          highlights = {},
        },
        {
          text = "still red",
          highlights = {
            {
              from = 0,
              to = 8,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
          },
        },
      }, result)
    end)
  end)

  describe("start_highlighting_at (offset)", function()
    it("crops highlights crossing the offset", function()
      local lines = { "-- \27[31mhello" }
      -- text: "-- hello" (len 8)
      -- red starts at 3 (h)
      -- offset 4 (e)
      -- Should crop 'h', start at 'e'
      local result = lexer.lex(lines, true, 4)

      assert.combinators.match({
        {
          highlights = {
            {
              from = 4,
              to = 7, -- 'o' is at 7
              style = { foreground = { set = true, value = { name = 1 } } },
            },
          },
        },
      }, result)
    end)

    it("excludes highlights entirely before the offset", function()
      local lines = { "\27[31mred \27[0mplain" }
      -- text: "red plain"
      -- red: 0-2
      -- offset: 4 (starts at 'p')
      local result = lexer.lex(lines, true, 4)

      assert.combinators.match({
        {
          highlights = {},
        },
      }, result)
    end)

    it("includes highlights entirely after the offset", function()
      local lines = { "plain \27[31mred" }
      -- text: "plain red"
      -- red: 6-8
      -- offset: 2
      local result = lexer.lex(lines, true, 2)

      assert.combinators.match({
        {
          highlights = {
            {
              from = 6,
              to = 8,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
          },
        },
      }, result)
    end)

    it("handles offsets larger than the line length", function()
      local lines = { "\27[31mshort" }
      local result = lexer.lex(lines, true, 10)

      assert.combinators.match({
        {
          highlights = {},
        },
      }, result)
    end)
  end)

  describe("streaming / chunking", function()
    it("accepts a seed style and returns the last style", function()
      local seed = styles.none()
      seed.foreground.set = true
      seed.foreground.value = { name = 1 } -- Red

      local lines = { "starts red\27[32m ends green" }
      local result, last_style = lexer.lex(lines, true, 0, seed)

      -- Check if "starts red" is actually red
      assert.combinators.match({
        {
          text = "starts red ends green",
          highlights = {
            {
              from = 0,
              to = 9,
              style = { foreground = { set = true, value = { name = 1 } } },
            },
            {
              from = 10,
              to = 20,
              style = { foreground = { set = true, value = { name = 2 } } },
            },
          },
        },
      }, result)

      -- Check if last_style is green
      assert.combinators.match({
        foreground = { set = true, value = { name = 2 } },
      }, last_style)
    end)
  end)
end)
