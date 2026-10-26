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

    it("attaches to the buffer only once", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[31mred" })

      local original_attach = vim.api.nvim_buf_attach
      local attaches = 0
      vim.api.nvim_buf_attach = function(...)
        attaches = attaches + 1
        return original_attach(...)
      end

      b.once(buffer)
      b.once(buffer)
      b.once(buffer)
      vim.api.nvim_buf_attach = original_attach

      assert.equals(1, attaches)
    end)

    it("strips non-modifiable buffers and keeps them non-modifiable", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[31mred" })
      vim.bo[buffer].modifiable = false

      b.once(buffer)

      assert.combinators.match({ "red" }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
      assert.is_false(vim.bo[buffer].modifiable)
    end)

    it("starts highlighting at line_starts_at", function()
      local b = baleia.setup({ async = false, line_starts_at = 3 })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[31m; red" })

      b.once(buffer)

      local extmarks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
      assert.equals(1, #extmarks)
      assert.equals(2, extmarks[1][3])
      assert.equals(5, extmarks[1][4].end_col)
    end)
  end)

  describe("buf_set_lines", function()
    it("sets lines and colors them", function()
      local b = baleia.setup({ async = false })

      b.buf_set_lines(buffer, 0, -1, false, { "\x1b[34mBlue" })

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "Blue" }, lines)
    end)

    it("accepts negative indices", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "x" })

      b.buf_set_lines(buffer, -1, -1, true, { "\x1b[31mappended" })

      local extmarks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
      assert.equals(1, #extmarks)
      assert.equals(1, extmarks[1][2])
      assert.equals(8, extmarks[1][4].end_col)
    end)

    it("still errors on out-of-bounds indices when strict", function()
      local b = baleia.setup({ async = false })

      assert.has_error(function()
        b.buf_set_lines(buffer, -100, -1, true, { "x" })
      end)
    end)

    it("treats buffer 0 as the current buffer", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_set_current_buf(buffer)
      b.buf_set_lines(buffer, 0, -1, false, { "\x1b[31mred" })
      b.automatically(buffer)

      b.buf_set_lines(0, 1, 1, false, { "\x1b[0mplain" })
      vim.wait(100)

      local extmarks = vim.api.nvim_buf_get_extmarks(buffer, -1, { 1, 0 }, { 1, -1 }, {})
      assert.equals(0, #extmarks)
    end)
  end)

  it("restores highlight groups after a colorscheme change", function()
    local b = baleia.setup({ async = false, name = "BaleiaColorSchemeTest" })
    b.buf_set_lines(buffer, 0, -1, false, { "\x1b[31mred" })
    local hl_group = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })[1][4].hl_group

    vim.cmd("hi clear")
    vim.api.nvim_exec_autocmds("ColorScheme", {})

    assert.truthy(vim.api.nvim_get_hl(0, { name = hl_group }).fg)
  end)

  describe("buf_set_text", function()
    it("sets text and colors them", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Prefix " })

      b.buf_set_text(buffer, 0, 7, 0, 7, { "\x1b[33mSuffix" })

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "Prefix Suffix" }, lines)
    end)

    it("colors text inserted mid-line", function()
      local b = baleia.setup({ async = false })
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Prefix " })

      b.buf_set_text(buffer, 0, 7, 0, 7, { "\x1b[33mSuffix" })

      local extmarks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
      assert.equals(1, #extmarks)
      assert.equals(7, extmarks[1][3])
      assert.equals(13, extmarks[1][4].end_col)
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

    -- on_lines colors on the next schedule tick, even when async is false
    local function settle()
      local done = false
      vim.schedule(function()
        done = true
      end)
      assert.is_true(vim.wait(1000, function()
        return done
      end))
    end

    local function highlight_spans(row)
      local spans = {}
      local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, { row, 0 }, { row, -1 }, { details = true })
      for _, mark in ipairs(marks) do
        if mark[4].hl_group and mark[4].end_col then
          table.insert(spans, { mark[3], mark[4].end_col })
        end
      end
      return spans
    end

    it("does not color lines appended after a trailing reset", function()
      local b = baleia.setup({ async = false })
      b.automatically(buffer)

      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "prefix \x1b[31mred\x1b[0m normal" })
      settle()
      assert.combinators.match({ "prefix red normal" }, vim.api.nvim_buf_get_lines(buffer, 0, 1, false))

      vim.api.nvim_buf_set_lines(buffer, -1, -1, false, {
        "This line has no ANSI codes and should use the default color.",
      })
      settle()
      assert.combinators.match({
        "This line has no ANSI codes and should use the default color.",
      }, vim.api.nvim_buf_get_lines(buffer, 1, 2, false))

      assert.combinators.match({ { 7, 10 } }, highlight_spans(0))
      assert.combinators.match({}, highlight_spans(1))
    end)

    it("does not color lines appended after a reset at the end of the line", function()
      local b = baleia.setup({ async = false })
      b.automatically(buffer)

      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "prefix \x1b[31mred\x1b[0m" })
      settle()
      assert.combinators.match({ "prefix red" }, vim.api.nvim_buf_get_lines(buffer, 0, 1, false))

      vim.api.nvim_buf_set_lines(buffer, -1, -1, false, { "plain" })
      settle()
      assert.combinators.match({ "plain" }, vim.api.nvim_buf_get_lines(buffer, 1, 2, false))

      assert.combinators.match({ { 7, 10 } }, highlight_spans(0))
      assert.combinators.match({}, highlight_spans(1))
    end)

    it("colors lines appended after an open color", function()
      local b = baleia.setup({ async = false })
      b.automatically(buffer)

      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "prefix \x1b[31mred" })
      settle()
      assert.combinators.match({ "prefix red" }, vim.api.nvim_buf_get_lines(buffer, 0, 1, false))

      vim.api.nvim_buf_set_lines(buffer, -1, -1, false, { "carried" })
      settle()
      assert.combinators.match({ "carried" }, vim.api.nvim_buf_get_lines(buffer, 1, 2, false))

      assert.combinators.match({ { 7, 10 } }, highlight_spans(0))
      assert.combinators.match({ { 0, 7 } }, highlight_spans(1))
    end)
  end)
end)
