local scanner = require("baleia.scanner")

describe("baleia.scanner", function()
  describe("is_reset_boundary", function()
    it("returns true for a line ending with \\x1b[0m", function()
      assert.is_true(scanner.is_reset_boundary("some text\x1b[0m"))
    end)

    it("returns true for a line ending with bare \\x1b[m (no digits)", function()
      assert.is_true(scanner.is_reset_boundary("some text\x1b[m"))
    end)

    it("returns false for a line ending with a color code", function()
      assert.is_false(scanner.is_reset_boundary("some text\x1b[31m"))
    end)

    it("returns false when a color code follows the reset", function()
      assert.is_false(scanner.is_reset_boundary("\x1b[0m\x1b[31mred"))
    end)

    it("returns true when reset is mid-line but is the last escape", function()
      assert.is_true(scanner.is_reset_boundary("\x1b[31mred\x1b[0m plain text"))
    end)

    it("returns false for a line with no ANSI codes", function()
      assert.is_false(scanner.is_reset_boundary("plain text"))
    end)

    it("returns false for an empty line", function()
      assert.is_false(scanner.is_reset_boundary(""))
    end)
  end)

  describe("find_split", function()
    local buffer

    before_each(function()
      buffer = vim.api.nvim_create_buf(false, true)
    end)

    it("returns the line number of the nearest reset boundary before w0", function()
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
        "line 0",
        "\x1b[31mred\x1b[0m", -- reset at line 1
        "line 2",
        "line 3",
      })
      assert.equals(1, scanner.find_split(buffer, 3))
    end)

    it("returns 0 when no reset is found", function()
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
        "\x1b[31mred",
        "\x1b[32mgreen",
        "\x1b[33myellow",
      })
      assert.equals(0, scanner.find_split(buffer, 2))
    end)

    it("returns 0 when w0 is at the top of the file", function()
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
        "\x1b[31mred\x1b[0m",
        "line 1",
      })
      assert.equals(0, scanner.find_split(buffer, 0))
    end)

    it("finds the nearest reset, not the first one", function()
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
        "\x1b[31mred\x1b[0m", -- reset at line 0
        "line 1",
        "\x1b[32mgreen\x1b[0m", -- reset at line 2
        "line 3",
        "line 4",
      })
      -- scanning from line 4 should find line 2, not line 0
      assert.equals(2, scanner.find_split(buffer, 4))
    end)
  end)
end)
