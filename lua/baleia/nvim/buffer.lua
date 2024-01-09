local M = {}

local END_OF_FILE = -1

---@param logger Logger
---@param namespace integer
---@param buffer buffer
function M.clear_empty_extmarks(logger, namespace, buffer)
  local opts = { type = "highlight", hl_name = false, details = true }
  local status, extmarks = pcall(function()
    return vim.api.nvim_buf_get_extmarks(buffer, namespace, 0, -1, opts)
  end)

  local logfn = not status and logger.error or logger.debug
  logfn("vim.api.nvim_buf_get_extmarks", {
    result = status and { number_of_marks = #extmarks },
    params = {
      buffer = buffer,
      namespace = namespace,
      start_row = 0,
      end_row = -1,
      options = opts,
    },
  })

  if not status then
    return
  end

  local removed = {}
  for _, mark in ipairs(extmarks) do
    local id, row, column, details = mark[1], mark[2], mark[3], mark[4]

    if row == details.end_row and column == details.end_col then
      vim.api.nvim_buf_del_extmark(buffer, opts.namespace, id)
      table.insert(removed, id)
    end
  end

  logfn("vim.api.nvim_buf_del_extmark", {
    params = {
      buffer = buffer,
      namespace = namespace,
      ids = removed,
    },
  })
end

function M.set_lines(logger, buffer, start, end_, strict_indexing, lines)
  local status, value = pcall(function()
    return vim.api.nvim_buf_set_lines(buffer, start, end_, strict_indexing, lines)
  end)

  local logfn = not status and logger.error or logger.debug
  logfn("vim.api.nvim_buf_set_lines", {
    result = value,
    params = {
      buffer = buffer,
      start = start,
      end_ = end_,
      strict_indexing = strict_indexing,
      lines = lines,
    },
  })

  return value
end

function M.set_text(logger, buffer, start_row, start_col, end_row, end_col, lines)
  local status, value = pcall(function()
    return vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, lines)
  end)

  local logfn = not status and logger.error or logger.debug
  logfn("vim.api.nvim_buf_set_text", {
    result = value,
    params = {
      buffer = buffer,
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
      lines = lines,
    },
  })

  return value
end

function M.get_lines(logger, buffer, start_row, end_row)
  local status, value = pcall(function()
    return vim.api.nvim_buf_get_lines(buffer, start_row or 0, end_row or END_OF_FILE, true)
  end)

  local logfn = not status and logger.error or logger.debug
  logfn("vim.api.nvim_buf_get_lines", {
    result = value,
    params = {
      buffer = buffer,
      start_row = start_row or 0,
      end_row = end_row or END_OF_FILE,
    },
  })

  return value
end

function M.create_highlight(logger, name, attributes)
  local status, value = pcall(function()
    return vim.api.nvim_set_hl(0, name, attributes)
  end)

  local logfn = not status and logger.error or logger.debug
  logfn("vim.api.nvim_set_hl", {
    result = value,
    params = {
      namespace = 0,
      name = name,
      attributes = attributes,
    },
  })

  return value
end

function M.add_highlight(logger, buffer, ns, hlgroup, line, start_col, end_col)
  local status, value = pcall(function()
    return vim.api.nvim_buf_add_highlight(buffer, ns, hlgroup, line, start_col, end_col or END_OF_FILE)
  end)

  local logfn = not status and logger.error or logger.debug
  logfn("vim.api.nvim_buf_add_highlight", {
    result = value,
    params = {
      buffer = buffer,
      namespace = ns,
      hlgroup = hlgroup,
      line = line,
      start_col = start_col,
      end_col = end_col,
    },
  })

  return value
end

M.last_row = vim.api.nvim_buf_line_count
M.get_name = vim.api.nvim_buf_get_name

function M.is_empty(buffer)
  return vim.api.nvim_buf_line_count(buffer) <= 0
end

function M.get_var(_, buffer, varname)
  return vim.api.nvim_buf_call(buffer, function()
    return vim.b[varname]
  end)
end

function M.set_var(logger, buffer, varname, value)
  logger.info("vim.api.nvim_buf_set_var", {
    buffer = buffer,
    varname = varname,
    value = value,
  })

  return vim.api.nvim_buf_set_var(buffer, varname, value)
end

function M.on_new_lines(logger, buffer, namespace, fn)
  if M.get_var(logger, buffer, "baleia_on_new_lines") then
    logger.debug("Skipping buffer.on_new_lines", { buffer = buffer })
    return
  end

  M.set_var(logger, buffer, "baleia_on_new_lines", true)

  logger.info("vim.api.nvim_buf_attach", { buffer = buffer, namespace = namespace })

  vim.api.nvim_buf_attach(buffer, false, {
    on_bytes = function(_, _, _, start_row, _, _, old_end_row, _, _, new_end_row)
      if old_end_row < new_end_row then
        local end_row = start_row + new_end_row

        logger.debug("buffer.on_new_lines", {
          buffer = buffer,
          namespace = namespace,
          start_row = start_row,
          end_row = end_row,
        })

        fn(buffer, namespace, start_row, end_row)
      end
    end,
  })
end

function M.set_options(logger, buffer, options)
  for option, value in pairs(options) do
    local status, result = pcall(function()
      vim.api.nvim_set_option_value(option, value, { buf = buffer })
    end)

    local logfn = not status and logger.error or logger.debug
    logfn("vim.api.nvim_buf_set_option", {
      result = result,
      params = { buffer = buffer, name = option, value = value },
    })
  end
end

function M.with_options(logger, buffer, options, thunk)
  local old_options = {}
  for option, _ in pairs(options) do
    old_options[option] = vim.api.nvim_get_option_value(option, { buf = buffer })
  end

  M.set_options(logger, buffer, options)
  local result = thunk()
  M.set_options(logger, buffer, old_options)
  return result
end

return M
