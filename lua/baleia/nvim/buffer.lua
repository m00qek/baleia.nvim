local buf = {}

local END_OF_FILE = -1
function buf.set_lines(logger, buffer, start, end_, strict_indexing, lines)
  local status, value = pcall(function()
    return vim.api.nvim_buf_set_lines(buffer, start, end_, strict_indexing, lines)
  end)

  local logfn = not status and logger.error or logger.debug
  logfn('vim.api.nvim_buf_set_lines', {
    result = value,
    params = {
      buffer = buffer,
      start = start,
      end_ = end_,
      strict_indexing = strict_indexing,
      lines = lines,
    }
  })

  return value
end

function buf.set_text(logger, buffer, start_row, start_col, end_row, end_col, lines)
  local status, value = pcall(function()
    return vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, lines)
  end)

  local logfn = not status and logger.error or logger.debug
  logfn('vim.api.nvim_buf_set_text', {
    result = value,
    params = {
      buffer = buffer,
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
      lines = lines,
    }
  })

  return value
end

function buf.get_lines(logger, buffer, start_row, end_row)
  local status, value = pcall(function()
    return vim.api.nvim_buf_get_lines(
      buffer,
      start_row or 0,
      end_row or END_OF_FILE,
      true)
  end)

  local logfn = not status and logger.error or logger.debug
  logfn('vim.api.nvim_buf_get_lines', {
    result = value,
    params = {
      buffer = buffer,
      start_row = start_row or 0,
      end_row = end_row or END_OF_FILE,
    }
  })

  return value
end

function buf.create_highlight(logger, name, attributes)
  local status, value = pcall(function()
    return vim.api.nvim_set_hl(0, name, attributes)
  end)

  local logfn = not status and logger.error or logger.debug
  logfn('vim.api.nvim_set_hl', {
    result = value,
    params = {
      namespace = 0,
      name = name,
      attributes = attributes
    }
  })

  return value
end

function buf.add_highlight(logger, buffer, ns, hlgroup, line, start_col, end_col)
  local status, value = pcall(function()
    return vim.api.nvim_buf_add_highlight(
      buffer,
      ns,
      hlgroup,
      line,
      start_col,
      end_col or END_OF_FILE)
  end)

  local logfn = not status and logger.error or logger.debug
  logfn('vim.api.nvim_buf_add_highlight', {
    result = value,
    params = {
      buffer = buffer,
      namespace = ns,
      hlgroup = hlgroup,
      line = line,
      start_col = start_col,
      end_col = end_col,
    }
  })

  return value
end

buf.last_row = vim.api.nvim_buf_line_count
buf.get_name = vim.api.nvim_buf_get_name

function buf.is_empty(buffer)
  return vim.api.nvim_buf_line_count(buffer) <= 0
end

function buf.get_var(_, buffer, varname)
  return vim.api.nvim_buf_call(buffer, function() return vim.b[varname] end)
end

function buf.set_var(logger, buffer, varname, value)
  logger.info('vim.api.nvim_buf_set_var', {
    buffer = buffer,
    varname = varname,
    value = value,
  })

  return vim.api.nvim_buf_set_var(buffer, varname, value)
end

function buf.on_new_lines(logger, buffer, ns, fn)
  if buf.get_var(logger, buffer, 'baleia_on_new_lines') then
    logger.debug('Skipping buffer.on_new_lines', { buffer = buffer })
    return
  end

  buf.set_var(logger, buffer, 'baleia_on_new_lines', true)

  logger.info('vim.api.nvim_buf_attach', { buffer = buffer, namespace = ns })

  vim.api.nvim_buf_attach(buffer, false, {
    on_bytes = function (_, _, _, start_row, _, _, old_end_row, _, _, new_end_row)
      if old_end_row < new_end_row then
        local end_row = start_row + new_end_row

        logger.debug('buffer.on_new_lines', {
          buffer = buffer,
          namespace = ns,
          start_row = start_row,
          end_row = end_row,
        })

        fn(buffer, ns, start_row, end_row)
      end
    end
  })
end

function buf.set_options(logger, buffer, options)
  for option, value in pairs(options) do
    local status, result = pcall(function()
      vim.api.nvim_buf_set_option(buffer, option, value)
    end)

    local logfn = not status and logger.error or logger.debug
    logfn('vim.api.nvim_buf_set_option', {
      result = result,
      params = { buffer = buffer, name = option, value = value }
    })
  end
end

function buf.with_options(logger, buffer, options, thunk)
  local old_options = { }
  for option, _ in pairs(options) do
    old_options[option] = vim.api.nvim_buf_get_option(buffer, option)
  end

  buf.set_options(logger, buffer, options)
  local result = thunk()
  buf.set_options(logger, buffer, old_options)
  return result
end

return buf
