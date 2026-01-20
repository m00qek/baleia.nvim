local options = require("baleia.options")
local text = require("baleia.text")

local nvim = require("baleia.nvim")

local M = {}

local options = require("baleia.options")
local text = require("baleia.text")

local nvim = require("baleia.nvim")

local M = {}

local tasks = {}
local next_task_id = 0

local function work_fn(encoded_args)
  local decoded = vim.mpack.decode(encoded_args)
  local basic_opts, lines, offset, task_id = unpack(decoded)
  local marks, highlights = require("baleia.text").colors(basic_opts, lines, offset)
  return vim.mpack.encode({ marks, highlights, task_id })
end

local function after_work_fn(encoded_result)
  local marks, highlights, task_id = unpack(vim.mpack.decode(encoded_result))
  local context = tasks[task_id]
  if context then
    tasks[task_id] = nil
    if next(marks) then
      nvim.highlight.all(context.opts.logger, context.opts.namespace, context.buffer, marks, highlights)
    end
  end
end

local work = vim.loop.new_work(work_fn, after_work_fn)

local function last_column(lines)
  local lastline = lines[#lines]
  return #lastline
end

local function colorize_async(opts, buffer, lines, offset)
  local task_id = next_task_id
  next_task_id = next_task_id + 1
  tasks[task_id] = { opts = opts, buffer = buffer }

  work:queue(vim.mpack.encode({ options.basic(opts), lines, offset, task_id }))
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
