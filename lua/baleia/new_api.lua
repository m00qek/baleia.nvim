local lexer = require("baleia.lexer")
local renderer = require("baleia.renderer")
local styles = require("baleia.styles")
local text = require("baleia.text")

local M = {}

local tasks = {}
local next_task_id = 0

local function worker_entry_point(encoded_args)
  local decoded = vim.mpack.decode(encoded_args)
  local lines, strip, offset, seed, task_id = unpack(decoded)

  local items, last_style = require("baleia.lexer").lex(lines, strip, offset, seed)
  return vim.mpack.encode({ items, last_style, task_id })
end

local function on_work_done(encoded_result)
  local decoded = vim.mpack.decode(encoded_result)
  local items, last_style, task_id = unpack(decoded)

  vim.schedule(function()
    local callback = tasks[task_id]
    if callback then
      tasks[task_id] = nil
      callback(items, last_style)
    end
  end)
end

local work_handle = vim.loop.new_work(worker_entry_point, on_work_done)

---@param start_idx integer
---@param end_idx integer
---@param chunk_size integer
---@param async boolean
---@param seed_style baleia.styles.Style
---@param strip_ansi boolean
---@param fetch_lines_fn fun(s: integer, e: integer): string[]
---@param render_fn fun(s: integer, items: baleia.LexerItem[])
local function run_in_chunks(start_idx, end_idx, chunk_size, async, seed_style, strip_ansi, fetch_lines_fn, render_fn)
  local function process_chunk(current_start, current_seed)
    if current_start > end_idx then
      return
    end

    local current_end = math.min(current_start + chunk_size - 1, end_idx)
    local lines = fetch_lines_fn(current_start, current_end)

    if async then
      local task_id = next_task_id
      next_task_id = next_task_id + 1

      tasks[task_id] = function(items, last_style)
        render_fn(current_start, items)
        process_chunk(current_end + 1, last_style)
      end

      local queued = work_handle:queue(vim.mpack.encode({ lines, strip_ansi, 0, current_seed, task_id }))
      if not queued then
        tasks[task_id] = nil
        vim.notify("Baleia: Failed to queue async task", vim.log.levels.ERROR)
      end
    else
      local items, last_style = lexer.lex(lines, strip_ansi, 0, current_seed)
      render_fn(current_start, items)
      process_chunk(current_end + 1, last_style)
    end
  end

  process_chunk(start_idx, seed_style)
end

---@param options baleia.options.Complete
---@param buffer integer
function M.once(options, buffer)
  local total_lines = vim.api.nvim_buf_line_count(buffer)

  run_in_chunks(
    0,
    total_lines - 1,
    options.chunk_size,
    options.async,
    styles.none(),
    options.strip_ansi_codes,
    function(s, e)
      return vim.api.nvim_buf_get_lines(buffer, s, e + 1, false)
    end,
    function(s, items)
      renderer.render(buffer, options.namespace, s, items, options, options.strip_ansi_codes)
    end
  )
end

function M.buf_set_lines(options, buffer, start, end_, strict_indexing, replacement)
  vim.api.nvim_buf_set_lines(buffer, start, end_, strict_indexing, text.content(options, replacement))

  run_in_chunks(
    1,
    #replacement,
    options.chunk_size,
    options.async,
    styles.none(),
    options.strip_ansi_codes,
    function(s, e)
      local chunk_lines = {}
      for i = s, e do
        table.insert(chunk_lines, replacement[i])
      end
      return chunk_lines
    end,
    function(s, items)
      local buffer_row = start + (s - 1)
      renderer.render(buffer, options.namespace, buffer_row, items, options, false)
    end
  )
end

function M.buf_set_text(options, buffer, start_row, start_col, end_row, end_col, replacement)
  vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, text.content(options, replacement))

  local first_line_items, seed_style = lexer.lex({ replacement[1] }, options.strip_ansi_codes, start_col)
  renderer.render(buffer, options.namespace, start_row, first_line_items, options, false)

  if #replacement > 1 then
    run_in_chunks(
      2,
      #replacement,
      options.chunk_size,
      options.async,
      seed_style,
      options.strip_ansi_codes,
      function(s, e)
        local chunk_lines = {}
        for i = s, e do
          table.insert(chunk_lines, replacement[i])
        end
        return chunk_lines
      end,
      function(s, items)
        local buffer_row = start_row + (s - 1)
        renderer.render(buffer, options.namespace, buffer_row, items, options, false)
      end
    )
  end
end

return M
