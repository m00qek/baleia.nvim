local nvim = require("baleia.nvim")
local options = require("baleia.options")
local text = require("baleia.text")

local M = {}

---@param opts CompleteOptions
---@param buffer buffer
---@param marks Mark[]
---@param highlights table<string, HighlightAttributes>
local function highlight(opts, buffer, marks, highlights)
  if next(marks) then
    nvim.highlight.all(opts.logger, opts.namespace, buffer, marks, highlights)
  end

  vim.schedule(function()
    local extmarks = vim.api.nvim_buf_get_extmarks(
      buffer,
      opts.namespace,
      0,
      -1,
      { type = "highlight", hl_name = false, details = true }
    )

    for _, mark in ipairs(extmarks) do
      local id, row, column, details = mark[1], mark[2], mark[3], mark[4]

      if row == details.end_row and column == details.end_col then
        vim.api.nvim_buf_del_extmark(buffer, opts.namespace, id)
      end
    end
  end)
end

local function sync(opts, buffer, lines, offset)
  local marks, highlights = text.colors(options.basic(opts), lines, offset)
  highlight(opts, buffer, marks, highlights)
end

local function async(opts, buffer, lines, offset)
  local callback = nil

  callback = vim.loop.new_async(function(result)
    local marks, highlights = unpack(vim.mpack.decode(result))
    highlight(opts, buffer, marks, highlights)

    if callback then
      vim.loop.close(callback)
    end
  end)

  local taskfn = function(donefn, arguments)
    local decoded = vim.mpack.decode(arguments)
    local result = { require("baleia.text").colors(unpack(decoded)) }
    vim.loop.async_send(donefn, vim.mpack.encode(result))
  end

  vim.loop.new_thread(taskfn, callback, vim.mpack.encode({ options.basic(opts), lines, offset }))
end

---@param opts CompleteOptions
---@param buffer buffer
---@param lines string[]
---@param offset OffsetConfig
function M.run(opts, buffer, lines, offset)
  if opts.async then
    async(opts, buffer, lines, offset)
    return
  end

  sync(opts, buffer, lines, offset)
end

return M
