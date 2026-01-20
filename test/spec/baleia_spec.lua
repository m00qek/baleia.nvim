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
    local nvim_internal = require("baleia.nvim")
    local original_on_new_lines = nvim_internal.buffer.on_new_lines

    after_each(function()
      nvim_internal.buffer.on_new_lines = original_on_new_lines
    end)

    it("registers a callback that colors new lines", function()
      local captured_callback
      nvim_internal.buffer.on_new_lines = function(_, _, _, fn)
        captured_callback = fn
      end

      local b = baleia.setup({ async = false })
      b.automatically(buffer)

      assert.is_not_nil(captured_callback)

      -- Simulate adding lines
      -- We must set the buffer content first because the callback reads it
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[35mAuto" })

      -- Manually trigger the callback
      -- fn(buffer, namespace, start_row, end_row)
      -- We simulate adding 1 line at row 0.
      captured_callback(buffer, 0, 0, 1)

      -- The callback uses vim.schedule for stripping.
      -- So we still need a small wait or check schedule.
      vim.wait(50)

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.combinators.match({ "Auto" }, lines)
    end)
  end)
end)