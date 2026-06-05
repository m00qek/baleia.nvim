local baleia = require("baleia")
require("matcher_combinators.luassert")

describe("baleia", function()
  local buffer

  before_each(function()
    buffer = vim.api.nvim_create_buf(false, true)
  end)

  describe("once", function()
    it("strips ANSI codes and applies highlights", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[31mHello" })

      b.once(buffer)

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "Hello" }, lines)
    end)

    it("handles multiple lines", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[32mLine 1", "Line 2\x1b[0m" })

      b.once(buffer)

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "Line 1", "Line 2" }, lines)
    end)

    it("produces correct highlights across a reset boundary split", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
        "\x1b[31mred\x1b[0m",  -- split boundary: last escape is reset
        "\x1b[32mgreen",
      })

      b.once(buffer)

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "red", "green" }, lines)
      local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
      assert.truthy(#marks >= 2)
    end)

    it("works correctly when no reset exists (single block, same as before)", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
        "\x1b[31mred",
        "still red",
      })

      b.once(buffer)

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "red", "still red" }, lines)
      local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
      assert.truthy(#marks >= 2)
    end)

    it("strips all lines across both blocks when strip_ansi_codes is true", function()
      local b = baleia.setup({ async = false, strip_ansi_codes = true })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
        "above\x1b[31mred\x1b[0m",  -- split boundary
        "\x1b[32mbelow",
      })

      b.once(buffer)

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "abovered", "below" }, lines)
    end)

    it("respects line_starts_at: highlights begin at the configured column", function()
      -- line_starts_at = 3 means skip the first 2 bytes (e.g. Conjure's "; " prefix)
      local b = baleia.setup({ async = false, line_starts_at = 3 })
      -- "xx" is the 2-byte prefix that should not be highlighted
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "xx\x1b[31mHello" })

      b.once(buffer)

      local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
      assert.truthy(#marks > 0)
      -- The highlight must start at column 2 (0-indexed), not 0
      assert.equals(2, marks[1][3])
    end)
  end)

  describe("buf_set_lines", function()
    it("sets lines and colors them", function()
      local b = baleia.setup({ async = false })

      b.buf_set_lines(buffer, 0, -1, false, { "\x1b[34mBlue" })

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "Blue" }, lines)
    end)
  end)

  describe("buf_set_text", function()
    it("sets text and colors them", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Prefix " })

      b.buf_set_text(buffer, 0, 7, 0, 7, { "\x1b[33mSuffix" })

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "Prefix Suffix" }, lines)
    end)
  end)

  describe("automatically", function()
    it("registers a callback that colors new lines", function()
      local b = baleia.setup({ async = false })
      b.automatically(buffer)

      -- Simulate adding lines
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[35mAuto" })

      -- The callback uses vim.schedule.
      vim.wait(200, function()
        local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
        return lines[1] == "Auto"
      end)

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "Auto" }, lines)

      local extmarks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {})
      assert.truthy(#extmarks > 0)
    end)
  end)
end)
