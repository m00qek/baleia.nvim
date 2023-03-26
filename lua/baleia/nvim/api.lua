local api = {}

function api.create_namespace(name)
  return vim.api.nvim_create_namespace(name)
end

function api.execute(logger, command)
  local status, result = pcall(function()
    return vim.fn.execute(command)
  end)

  if status then
    logger.debug('vim.fn.execute', { command = command, result = result })
  else
    logger.error('vim.fn.execute', { command = command, error = result })
  end

  return result
end

function api.highlights(logger, ns)
  local fn_name, status, result

  -- this is for older neovim versions
  fn_name = "nvim__get_hl_defs"
  if vim.api[fn_name] then
    status, result = pcall(function()
      return vim.api[fn_name](ns)
    end)
  end

  -- this is for neovim versions > 0.9.0
  fn_name = "nvim_get_hl"
  if vim.api[fn_name] then
    status, result = pcall(function()
      return vim.api[fn_name](ns, {})
    end)
  end

  local logfn = status and logger.debug or logger.error
  logfn("vim.api." .. fn_name, { params = { ns = ns } })

  return {
    undefined = function(hl_name)
      return not result[hl_name]
    end
  }
end

return api
