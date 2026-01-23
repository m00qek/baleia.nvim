local ansi = require("baleia.ansi")
local inspector = require("baleia.inspector")
local lexer = require("baleia.lexer")
local renderer = require("baleia.renderer")
local scheduler = require("baleia.scheduler")

local M = {}

-- track cancel functions per buffer (for once())
local active_cancels = {}

-- track internal updates (to prevent automatically() from processing them)
local internal_updates = {}

local function begin_internal_update(buffer)
  internal_updates[buffer] = (internal_updates[buffer] or 0) + 1
end

local function end_internal_update(buffer)
  internal_updates[buffer] = math.max(0, (internal_updates[buffer] or 1) - 1)
end

local function is_internal_update(buffer)
  return internal_updates[buffer] and internal_updates[buffer] > 0
end

---Parses the contents of {buffer} and colorizes them respecting any ANSI
---color codes present in the text.
---@param options baleia.Options
---@param buffer integer Buffer handle
function M.once(options, buffer)
  -- Cancel any existing processing for this buffer
  if active_cancels[buffer] then
    active_cancels[buffer]()
    active_cancels[buffer] = nil
  end

  -- mark as internal update before clearing namespace
  begin_internal_update(buffer)

  local cancel = scheduler.process_buffer(
    buffer,
    options.namespace,

    -- process_fn: lex lines
    function(lines, _, seed)
      local items, last_style = lexer.lex(
        lines,
        options.strip_ansi_codes,
        0, -- offset
        seed
      )
      return items, last_style
    end,

    -- render_fn: apply highlights (wrapped to track internal updates)
    function(start_row, items)
      begin_internal_update(buffer)

      renderer.render(
        buffer,
        options.namespace,
        start_row - 1, -- Convert to 0-indexed
        items,
        options,
        options.strip_ansi_codes -- Update text if stripping
      )

      end_internal_update(buffer)
    end,

    -- Options
    {
      chunk_size = options.chunk_size,
      async = options.async,
      initial_seed = {},
      on_complete = function()
        active_cancels[buffer] = nil
        end_internal_update(buffer) -- End the initial internal update
      end,
      on_error = function(err)
        vim.notify("Baleia: " .. err, vim.log.levels.WARN)
        active_cancels[buffer] = nil
        end_internal_update(buffer) -- End even on error
      end,
    }
  )

  active_cancels[buffer] = cancel
end

---Every time a new line is added to {buffer}, parses the new contents and
---colorizes them respecting any ANSI color codes present in the text.
---@param options baleia.Options
---@param buffer integer Buffer handle
function M.automatically(options, buffer)
  -- Check if already attached
  local status, active = pcall(vim.api.nvim_buf_get_var, buffer, "baleia_on_new_lines")
  if status and active then
    return
  end
  vim.api.nvim_buf_set_var(buffer, "baleia_on_new_lines", true)

  -- Track current processing to allow cancellation
  local current_cancel = nil

  vim.api.nvim_buf_attach(buffer, false, {
    on_lines = function(_, _, _, firstline, _, new_lastline)
      -- ✅ CRITICAL: Ignore internal updates (from once(), buf_set_lines, etc.)
      if is_internal_update(buffer) then
        return
      end

      if new_lastline <= firstline then
        return
      end

      -- Cancel previous processing for this region
      if current_cancel then
        current_cancel()
        current_cancel = nil
      end

      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buffer) then
          return
        end

        -- Get raw lines
        local raw_lines = vim.api.nvim_buf_get_lines(buffer, firstline, new_lastline, false)

        -- Check if any line has ANSI codes
        local has_ansi = false
        for _, line in ipairs(raw_lines) do
          if line and line:find(ansi.PATTERN) then
            has_ansi = true
            break
          end
        end

        -- Get seed style from previous line
        local seed = {}
        if firstline > 0 then
          seed = inspector.style_at_end_of_line(buffer, options.namespace, firstline - 1)
        end

        -- If stripping is enabled and ANSI codes exist, strip them from buffer first
        if options.strip_ansi_codes and has_ansi then
          begin_internal_update(buffer)
          local stripped_lines = ansi.strip(raw_lines)
          vim.api.nvim_buf_set_lines(buffer, firstline, new_lastline, false, stripped_lines)
          end_internal_update(buffer)
        end

        -- Then process and highlight
        current_cancel = scheduler.process_array(
          raw_lines,

          -- process_fn: lex lines
          function(lines, _, seed_style)
            local items, last_style = lexer.lex(
              lines,
              options.strip_ansi_codes,
              0, -- offset
              seed_style
            )
            return items, last_style
          end,

          -- render_fn: apply highlights (wrapped to track internal updates)
          function(start_idx, items)
            if not vim.api.nvim_buf_is_valid(buffer) then
              return
            end

            begin_internal_update(buffer)

            renderer.render(
              buffer,
              options.namespace,
              firstline + start_idx - 1,
              items,
              options,
              false -- Don't update text (already stripped above)
            )

            end_internal_update(buffer)
          end,

          {
            chunk_size = options.chunk_size,
            async = options.async,
            initial_seed = seed,
            on_complete = function()
              current_cancel = nil
            end,
          }
        )
      end)
    end,

    on_detach = function()
      if current_cancel then
        current_cancel()
      end
      pcall(vim.api.nvim_buf_del_var, buffer, "baleia_on_new_lines")
    end,
  })
end

---Sets (replaces) a line-range in the buffer, parses ANSI color codes and
---colorizes the resulting text accordingly.
---@param options baleia.Options
---@param buffer integer Buffer handle, or 0 for current buffer
---@param start integer First line index
---@param end_ integer Last line index, exclusive
---@param strict_indexing boolean Whether out-of-bounds should be an error
---@param replacement string[] Array of lines to use as replacement
function M.buf_set_lines(options, buffer, start, end_, strict_indexing, replacement)
  -- Mark as internal update
  begin_internal_update(buffer)

  -- Strip ANSI codes from buffer text FIRST
  vim.api.nvim_buf_set_lines(
    buffer,
    start,
    end_,
    strict_indexing,
    options.strip_ansi_codes and ansi.strip(replacement) or replacement
  )

  end_internal_update(buffer)

  -- Get seed style from previous line
  local seed = {}
  if start > 0 then
    seed = inspector.style_at_end_of_line(buffer, options.namespace, start - 1)
  end

  -- Process and highlight the replacement lines
  scheduler.process_array(
    replacement,

    -- process_fn: lex lines
    function(lines, _, seed_style)
      local items, last_style = lexer.lex(
        lines,
        options.strip_ansi_codes,
        0, -- offset
        seed_style
      )
      return items, last_style
    end,

    -- render_fn: apply highlights (wrapped to track internal updates)
    function(start_idx, items)
      if not vim.api.nvim_buf_is_valid(buffer) then
        return
      end

      begin_internal_update(buffer)

      renderer.render(
        buffer,
        options.namespace,
        start + start_idx - 1,
        items,
        options,
        false -- Don't update text (already stripped above)
      )

      end_internal_update(buffer)
    end,

    {
      chunk_size = options.chunk_size,
      async = options.async,
      initial_seed = seed,
    }
  )
end

---Sets (replaces) a range in the buffer, parses ANSI color codes and colorizes
---the resulting lines accordingly.
---@param options baleia.Options
---@param buffer integer Buffer handle, or 0 for current buffer
---@param start_row integer First line index
---@param start_col integer Starting column (byte offset) on first line
---@param end_row integer Last line index, inclusive
---@param end_col integer Ending column (byte offset) on last line, exclusive
---@param replacement string[] Array of lines to use as replacement
function M.buf_set_text(options, buffer, start_row, start_col, end_row, end_col, replacement)
  -- Mark as internal update
  begin_internal_update(buffer)

  -- Strip ANSI codes from buffer text FIRST
  vim.api.nvim_buf_set_text(
    buffer,
    start_row,
    start_col,
    end_row,
    end_col,
    options.strip_ansi_codes and ansi.strip(replacement) or replacement
  )

  end_internal_update(buffer)

  -- Get seed style
  local seed = {}
  if start_col > 0 then
    seed = inspector.style_at(buffer, options.namespace, start_row, start_col - 1)
  elseif start_row > 0 then
    seed = inspector.style_at_end_of_line(buffer, options.namespace, start_row - 1)
  end

  if #replacement == 0 then
    return
  end

  -- First line has column offset (process synchronously, outside async processor)
  begin_internal_update(buffer)
  local first_items, last_style = lexer.lex({ replacement[1] }, options.strip_ansi_codes, start_col, seed)
  renderer.render(buffer, options.namespace, start_row, first_items, options, false)
  end_internal_update(buffer)

  -- Remaining lines (if any) have no column offset
  if #replacement > 1 then
    local remaining = {}
    for i = 2, #replacement do
      table.insert(remaining, replacement[i])
    end

    scheduler.process_array(
      remaining,

      -- process_fn: lex lines
      function(lines, _, seed_style)
        return lexer.lex(lines, options.strip_ansi_codes, 0, seed_style)
      end,

      -- render_fn: apply highlights (wrapped to track internal updates)
      function(start_idx, items)
        if not vim.api.nvim_buf_is_valid(buffer) then
          return
        end

        begin_internal_update(buffer)

        renderer.render(buffer, options.namespace, start_row + start_idx, items, options, false)

        end_internal_update(buffer)
      end,

      {
        chunk_size = options.chunk_size,
        async = options.async,
        initial_seed = last_style, -- Seed from first line
      }
    )
  end
end

return M
