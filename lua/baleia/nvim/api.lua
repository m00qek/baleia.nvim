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

return api
