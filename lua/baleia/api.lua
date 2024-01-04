local options = require("baleia.options")
local text = require("baleia.text")

local nvim = require("baleia.nvim")

local M = {}

local function last_column(lines)
  local lastline = lines[#lines]
  return #lastline
end

local function colorize_async(opts, buffer, lines, offset)
  local callback = nil

  callback = vim.loop.new_async(function(result)
    local marks, highlights = unpack(vim.mpack.decode(result))

    if next(marks) then
      nvim.highlight.all(opts.logger, opts.namespace, buffer, marks, highlights)
    end

    vim.loop.close(callback)
  end)

  local taskfn = function(donefn, arguments)
    local decoded = vim.mpack.decode(arguments)
    local result = { require("baleia.text").colors(unpack(decoded)) }
    vim.loop.async_send(donefn, vim.mpack.encode(result))
  end

  vim.loop.new_thread(taskfn, callback, vim.mpack.encode({ options.basic(opts), lines, offset }))
end

local function colorize_sync(opts, buffer, lines, offset)
  local marks, highlights = text.colors(opts, lines, offset)

  if next(marks) then
    nvim.highlight.all(opts.logger, opts.namespace, buffer, marks, highlights)
  end
end

local function colorize(opts, buffer, lines, offset)
  local fn = opts.async and colorize_async or colorize_sync
  return fn(opts, buffer, lines, offset)
end

function M.once(opts, buffer)
  local raw_lines = nvim.buffer.get_lines(opts.logger, buffer)

  if opts.strip_ansi_codes then
    nvim.buffer.set_text(
      opts.logger,
      buffer,
      0,
      0,
      #raw_lines - 1,
      last_column(raw_lines),
      text.content(opts, raw_lines)
    )
  end

  colorize(opts, buffer, raw_lines, { global = { column = 0, line = 0 } })
end

function M.automatically(opts, buffer)
  nvim.buffer.on_new_lines(opts.logger, buffer, opts.namespace, function(_, _, start_row, end_row)
    if nvim.buffer.is_empty(buffer) then
      return
    end

    local raw_lines = nvim.buffer.get_lines(opts.logger, buffer, start_row, end_row)

    if opts.strip_ansi_codes then
      vim.schedule(function()
        nvim.buffer.set_text(
          opts.logger,
          buffer,
          start_row,
          0,
          end_row - 1,
          last_column(raw_lines),
          text.content(opts, raw_lines)
        )
      end)
    end

    colorize(opts, buffer, raw_lines, { global = { column = 0, line = start_row } })
  end)
end

function M.buf_set_lines(opts, buffer, start, end_, strict_indexing, raw_lines)
  nvim.buffer.set_lines(opts.logger, buffer, start, end_, strict_indexing, text.content(opts, raw_lines))

  colorize(opts, buffer, raw_lines, { global = { column = 0, line = start } })
end

function M.buf_set_text(opts, buffer, start_row, start_col, end_row, end_col, raw_lines)
  nvim.buffer.set_text(opts.logger, buffer, start_row, start_col, end_row, end_col, text.content(opts, raw_lines))

  colorize(opts, buffer, raw_lines, {
    global = { column = 0, line = start_row },
    lines = { [1] = { column = start_col, line = start_row } },
  })
end

return M
