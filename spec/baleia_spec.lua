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

    it("handles an empty buffer without hanging the internal-update counter", function()
      local b = baleia.setup({ async = false })
      b.once(buffer) -- empty buffer: both blocks are skipped

      -- If the counter is stuck, automatically() ignores all future edits.
      b.automatically(buffer)
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[31mHello" })

      vim.wait(300, function()
        return #vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {}) > 0
      end)

      local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {})
      assert.truthy(#marks > 0)
    end)

    it("can be called twice on the same buffer", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[31mFirst" })
      b.once(buffer)

      -- Change content and call again
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[32mSecond" })
      b.once(buffer)

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "Second" }, lines)
      local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
      assert.truthy(#marks > 0)
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

    it("seeds style from the previous line when inserting at row > 0", function()
      -- Establish a red style on row 0 (no reset at end so seed carries forward).
      local b = baleia.setup({ async = false, strip_ansi_codes = false })
      b.buf_set_lines(buffer, 0, -1, false, { "\x1b[31mred" })

      -- Insert a plain line at row 1; the lexer should seed red from row 0.
      b.buf_set_lines(buffer, 1, 2, false, { "plain" })

      local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, { 1, 0 }, { 1, -1 }, { details = true })
      assert.truthy(#marks > 0, "row 1 should inherit the red style seed")
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

    it("calling automatically() twice does not double-process changes", function()
      local b = baleia.setup({ async = false })
      b.automatically(buffer)
      b.automatically(buffer) -- should no-op; buffer already attached

      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[31mHi" })

      vim.wait(200, function()
        return #vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {}) > 0
      end)

      local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {})
      -- With two attachments we'd get double extmarks at col 0; with one, just one.
      assert.equals(1, #marks)
    end)

    it("propagates style seed from the previous line", function()
      -- Line 0 sets bold+red, with no reset at end.
      -- Line 1 is plain text; it should inherit the bold+red style as a seed.
      local b = baleia.setup({ async = false, strip_ansi_codes = false })
      b.automatically(buffer)

      -- Write line 0 (already has red style active, no reset)
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[31mred" })
      vim.wait(200, function()
        return #vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {}) > 0
      end)

      -- Append line 1 — no escape codes; style should carry over
      vim.api.nvim_buf_set_lines(buffer, 1, 2, false, { "also red" })
      vim.wait(200, function()
        -- Wait for the second line's extmarks to appear
        local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, { 1, 0 }, { 1, -1 }, { details = true })
        return #marks > 0
      end)

      local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, { 1, 0 }, { 1, -1 }, { details = true })
      assert.truthy(#marks > 0, "line 1 should inherit the red style from line 0")
    end)
  end)

  describe("two-block split", function()
    -- _w0 injects a fake first-visible-line so tests can exercise split>0
    -- without needing a real Neovim window. In production this is always derived
    -- from vim.fn.line("w0") - 1.

    it("highlights lines in both Block A and Block B when split > 0", function()
      -- w0=2: find_split scans backward from line 2 and finds the reset at line 1.
      -- Block A = [1, 3), Block B = [0, 1).
      local b = baleia.setup({ async = false, strip_ansi_codes = true, _w0 = 2 })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
        "\x1b[34mblue", -- line 0: Block B
        "\x1b[31mred\x1b[0m", -- line 1: reset boundary (split point)
        "\x1b[32mgreen", -- line 2: Block A (viewport)
      })

      b.once(buffer)

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "blue", "red", "green" }, lines)

      -- All three lines must have extmarks: Block A (lines 1-2) and Block B (line 0)
      local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
      assert.truthy(#marks >= 3, "expected highlights on all three lines, got " .. #marks)
    end)

    it("Block A seed is empty at a reset boundary so no style leaks from Block B", function()
      -- Line 0 sets bold+red with no reset. Line 1 resets at end → split point (w0=2).
      -- Block A starts at line 1 with seed={}; line 2 should NOT inherit bold from line 0.
      local b = baleia.setup({ async = false, strip_ansi_codes = false, _w0 = 2 })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
        "\x1b[1;31mbold-red", -- line 0: bold+red, no reset (Block B)
        "\x1b[0m", -- line 1: reset (split point, Block A starts here with seed={})
        "plain", -- line 2: no ANSI codes; receives no seed from Block B
      })

      b.once(buffer)

      -- Row 2 has no ANSI codes and Block A seed is {}, so no extmarks expected
      local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, { 2, 0 }, { 2, -1 }, { details = true })
      assert.equals(0, #marks, "line 2 must not inherit bold+red from Block B")
    end)
  end)

  describe("once() nvim_buf_attach accumulation", function()
    it("attaches the on_detach listener only once no matter how many times once() is called", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[31mHello" })

      local attach_count = 0
      local orig = vim.api.nvim_buf_attach
      vim.api.nvim_buf_attach = function(...)
        attach_count = attach_count + 1
        return orig(...)
      end

      b.once(buffer)
      b.once(buffer)
      b.once(buffer)

      vim.api.nvim_buf_attach = orig

      assert.equals(1, attach_count)
    end)
  end)

  describe("once cancellation", function()
    it("calling once() twice cancels the first in-flight run", function()
      -- Use async=true so the first once() schedules work that hasn't run yet.
      local b = baleia.setup({ async = true, chunk_size = 1 })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[31mFirst", "\x1b[32mSecond" })

      b.once(buffer) -- schedules async chunks

      -- Immediately replace content and call once() again before chunks run.
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[33mOnly" })
      b.once(buffer) -- should cancel the first run

      vim.wait(300, function()
        return #vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {}) > 0
      end)

      -- Buffer should reflect the second once() result, not a mix of both.
      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "Only" }, lines)
    end)
  end)
end)
