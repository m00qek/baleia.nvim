local M = {}

---Process items in chunks using vim.schedule (loop-based, no recursion)
---@param total_items integer Total number of items to process
---@param fetch_fn fun(start_idx: integer, end_idx: integer): any[] Function to fetch a chunk of items
---@param process_fn fun(chunk: any[], start_idx: integer, seed: any): result: any, next_seed: any
---@param render_fn fun(start_idx: integer, result: any)
---@param opts { chunk_size: integer, async: boolean, initial_seed: any, on_complete: function, on_error: function }
---@return fun() cancel_fn
function M.process(total_items, fetch_fn, process_fn, render_fn, opts)
  local initial_seed = opts.initial_seed or {}

  if total_items == 0 then
    if opts.on_complete then
      vim.schedule(opts.on_complete)
    end
    return function() end
  end

  -- State (captured in closure)
  local cancelled = false
  local current_seed = initial_seed
  local chunk_idx = 0

  -- Calculate chunk boundaries
  local first_chunk_size = math.min(opts.chunk_size, total_items)
  local chunks = {}

  -- First chunk
  table.insert(chunks, { start_idx = 1, end_idx = first_chunk_size })

  -- Remaining chunks
  local pos = first_chunk_size + 1
  while pos <= total_items do
    local chunk_end = math.min(pos + opts.chunk_size - 1, total_items)
    table.insert(chunks, { start_idx = pos, end_idx = chunk_end })
    pos = chunk_end + 1
  end

  local total_chunks = #chunks

  -- Cancel function
  local function cancel()
    cancelled = true
  end

  -- Process next chunk (called in loop)
  local function process_next_chunk()
    if cancelled then
      return
    end

    chunk_idx = chunk_idx + 1

    if chunk_idx > total_chunks then
      -- All done
      if opts.on_complete then
        vim.schedule(opts.on_complete)
      end
      return
    end

    local chunk_info = chunks[chunk_idx]
    local start_idx = chunk_info.start_idx
    local end_idx = chunk_info.end_idx

    -- Fetch chunk using provided fetch_fn
    local ok_fetch, chunk = pcall(fetch_fn, start_idx, end_idx)

    if not ok_fetch then
      if opts.on_error then
        opts.on_error("Fetch failed: " .. tostring(chunk))
      end
      return
    end

    -- Process
    local ok, result, next_seed = pcall(process_fn, chunk, start_idx, current_seed)

    if not ok then
      if opts.on_error then
        opts.on_error("Processing failed: " .. tostring(result))
      end
      return
    end

    -- Render
    local render_ok, render_err = pcall(render_fn, start_idx, result)
    if not render_ok then
      if opts.on_error then
        opts.on_error("Render failed: " .. tostring(render_err))
      end
      return
    end

    -- Update seed for next iteration
    current_seed = next_seed

    -- Continue to next chunk
    if chunk_idx < total_chunks then
      if opts.async and chunk_idx >= 1 then
        -- ASYNC MODE: Schedule next chunk (non-blocking)
        vim.schedule(process_next_chunk)
      else
        -- SYNC MODE: Process next chunk immediately (blocking loop)
        process_next_chunk()
      end
    else
      -- Last chunk, we're done
      if opts.on_complete then
        vim.schedule(opts.on_complete)
      end
    end
  end

  -- Start processing (first chunk is ALWAYS synchronous)
  process_next_chunk()

  return cancel
end

---Process buffer lines in chunks (lazy fetch from buffer)
---@param buffer integer
---@param namespace integer
---@param process_fn fun(lines: string[], start_row: integer, seed: any): result: any, next_seed: any
---@param render_fn fun(start_row: integer, result: any)
---@param opts table
---@return fun() cancel_fn
function M.process_buffer(buffer, namespace, process_fn, render_fn, opts)
  -- Clear namespace
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)

  -- Validate buffer
  if not vim.api.nvim_buf_is_valid(buffer) then
    if opts.on_error then
      opts.on_error("Buffer not valid")
    end
    return function() end
  end

  -- Get total line count (cheap, doesn't fetch lines)
  local total_lines = vim.api.nvim_buf_line_count(buffer)

  -- Create fetch function that lazily loads from buffer
  local function fetch_fn(start_idx, end_idx)
    if not vim.api.nvim_buf_is_valid(buffer) then
      error("Buffer no longer valid")
    end

    -- Convert 1-indexed to 0-indexed for Neovim API
    return vim.api.nvim_buf_get_lines(buffer, start_idx - 1, end_idx, false)
  end

  -- Delegate to process() with lazy fetch
  local cancel = M.process(total_lines, fetch_fn, process_fn, render_fn, opts)

  -- Auto-cancel on buffer delete
  vim.api.nvim_buf_attach(buffer, true, {
    on_detach = function()
      cancel()
    end,
  })

  return cancel
end

---Process in-memory array (convenience wrapper)
---@param items any[]
---@param process_fn fun(chunk: any[], start_idx: integer, seed: any): result: any, next_seed: any
---@param render_fn fun(start_idx: integer, result: any)
---@param opts table
---@return fun() cancel_fn
function M.process_array(items, process_fn, render_fn, opts)
  -- Create fetch function that extracts from array
  local function fetch_fn(start_idx, end_idx)
    local chunk = {}
    for i = start_idx, end_idx do
      table.insert(chunk, items[i])
    end
    return chunk
  end

  return M.process(#items, fetch_fn, process_fn, render_fn, opts)
end

return M
