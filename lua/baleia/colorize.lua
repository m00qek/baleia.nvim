local nvim = require("baleia.nvim")
local options = require("baleia.options")
local text = require("baleia.text")

local M = {}

---@param opts CompleteOptions
---@param buffer buffer
---@param marks Mark[]
---@param highlights { [string]: HighlightAttributes }
local function highlight(opts, buffer, marks, highlights)
  if next(marks) then
    nvim.highlight.all(opts.logger, opts.namespace, buffer, marks, highlights)
  end

  nvim.buffer.clear_empty_extmarks(opts.logger, opts.namespace, buffer)
end

local function sync(opts, buffer, lines, offset)
  local marks, highlights = text.colors(options.basic(opts), lines, offset)
  vim.schedule(function()
    highlight(opts, buffer, marks, highlights)
  end)
end

local function async(opts, buffer, lines, offset)
  local callback = nil

  callback = vim.loop.new_async(function(result)
    local marks, highlights = unpack(vim.mpack.decode(result --[[@as string]]) --[[@as table]])

    vim.schedule(function()
      highlight(opts, buffer, marks, highlights)
    end)

    if callback then
      vim.loop.close(callback)
    end
  end)

  local taskfn = function(donefn, arguments)
    local decoded = vim.mpack.decode(arguments --[[@as string]]) --[[@as table]]
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
