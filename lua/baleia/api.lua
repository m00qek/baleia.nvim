local ansi_codes = require("baleia.locations.ansi_codes")
local colorize = require("baleia.colorize")
local text = require("baleia.text")

local nvim = require("baleia.nvim")

local M = {}

local function strip_ansi_codes(opts, buffer, lines, row_offset)
  local empty = { "" }
  ansi_codes.foreach(lines, function(ansi_sequence, from, _)
    nvim.buffer.set_text(
      opts.logger,
      buffer,
      row_offset + from.line - 1,
      from.column - 1,
      row_offset + from.line - 1,
      #ansi_sequence + from.column - 1,
      empty
    )
  end, { backwards = true })
end

function M.once(opts, buffer)
  local raw_lines = nvim.buffer.get_lines(opts.logger, buffer)

  if opts.strip_ansi_codes then
    vim.schedule(function()
      strip_ansi_codes(opts, buffer, raw_lines, 0)
    end)
  end

  colorize.run(opts, buffer, raw_lines, { global = { column = 0, line = 0 } })
end

function M.automatically(opts, buffer)
  nvim.buffer.on_new_lines(opts.logger, buffer, opts.namespace, function(_, _, start_row, end_row)
    if nvim.buffer.is_empty(buffer) then
      return
    end

    local raw_lines = nvim.buffer.get_lines(opts.logger, buffer, start_row, end_row)

    if opts.strip_ansi_codes then
      vim.schedule(function()
        strip_ansi_codes(opts, buffer, raw_lines, start_row)
      end)
    end

    colorize.run(opts, buffer, raw_lines, { global = { column = 0, line = start_row } })
  end)
end

function M.buf_set_lines(opts, buffer, start, end_, strict_indexing, raw_lines)
  nvim.buffer.set_lines(opts.logger, buffer, start, end_, strict_indexing, text.content(opts, raw_lines))

  colorize.run(opts, buffer, raw_lines, { global = { column = 0, line = start } })
end

function M.buf_set_text(opts, buffer, start_row, start_col, end_row, end_col, raw_lines)
  nvim.buffer.set_text(opts.logger, buffer, start_row, start_col, end_row, end_col, text.content(opts, raw_lines))

  colorize.run(opts, buffer, raw_lines, {
    global = { column = 0, line = start_row },
    lines = { [1] = { column = start_col, line = start_row } },
  })
end

return M
