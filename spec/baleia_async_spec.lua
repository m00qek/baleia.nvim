require("matcher_combinators.luassert")
local baleia = require("baleia")

describe("baleia async", function()
  local buffer

  before_each(function()
    buffer = vim.api.nvim_create_buf(false, true)
  end)

  it("once strips ANSI codes and applies highlights asynchronously", function()
    local b = baleia.setup({ async = true, chunk_size = 10 })
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "\x1b[31mHello Async" })

    b.once(buffer)

    -- waits for the highlight to appear.
    vim.wait(1000, function()
      local extmarks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {})
      return #extmarks > 0
    end)

    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    assert.combinators.match({ "Hello Async" }, lines)

    local extmarks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
    assert.truthy(#extmarks > 0)

    local mark = extmarks[1]
    local hl_group = mark[4].hl_group
    local hl_def = vim.api.nvim_get_hl(0, { name = hl_group })
    assert.truthy(hl_def.fg)
  end)
end)
