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

    it("returns true for \\x1b[00m (double-zero reset)", function()
      assert.is_true(scanner.is_reset_boundary("text\x1b[00m"))
    end)

    it("returns false for a partial unset like \\x1b[22m (only clears bold)", function()
      assert.is_false(scanner.is_reset_boundary("text\x1b[22m"))
    end)

    it("returns false for a compound partial unset that clears only the basic SENTINEL fields", function()
      -- \x1b[39;49;22;23;24m clears fg, bg, bold, italic, underline — but NOT
      -- strikethrough, reverse, undercurl, etc. A SENTINEL that omits those
      -- extra fields would incorrectly report this as a full reset.
      assert.is_false(scanner.is_reset_boundary("text\x1b[39;49;22;23;24m"))
    end)

    it("returns false for a line ending with \\x1b[9m (sets strikethrough, not a reset)", function()
      assert.is_false(scanner.is_reset_boundary("text\x1b[9m"))
    end)

    it("returns false for \\x1b[7m (sets reverse video)", function()
      assert.is_false(scanner.is_reset_boundary("text\x1b[7m"))
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

    it("handles an empty buffer without error", function()
      -- empty buffer: nvim_buf_get_lines returns {} for any range
      assert.equals(0, scanner.find_split(buffer, 0))
    end)

    it("scans across chunk boundaries to find a distant reset", function()
      -- Build a buffer where the reset is more than SCAN_CHUNK (200) lines above w0
      local lines = {}
      for i = 1, 250 do
        lines[i] = "plain line " .. i
      end
      lines[1] = "\x1b[31mred\x1b[0m" -- reset only at line 0 (1-indexed here)
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

      -- w0 = 249 (last line, 0-indexed); the only reset is at line 0
      assert.equals(0, scanner.find_split(buffer, 249))
    end)
  end)
end)
