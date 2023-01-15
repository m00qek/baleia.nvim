local log = { }

local nvim = require("baleia.nvim")

local do_nothing = function() end

log.LEVELS = {
  ERROR = { priority = 10, color = 'red' },
  WARN  = { priority = 20, color = 'yellow' },
  INFO  = { priority = 30, color = 'green' },
  DEBUG = { priority = 40, color = 'grey' },
}

log.NULL_LOGGER = {
  show = function() vim.cmd('echom "Baleia logs are disabled."') end,
  info = do_nothing,
  warn = do_nothing,
  error = do_nothing,
  debug = do_nothing,
}

local function create(hlgroup)
  local bufname = 'baleia-log-' .. vim.fn.strftime('%s000')
  local buffer = vim.fn.bufadd(bufname)

  nvim.buffer.set_options(log.NULL_LOGGER, buffer, {
    modifiable = false,
    buftype = 'nofile',
    bufhidden = 'hide',
    swapfile = false,
  })

  for name, level in pairs(log.LEVELS) do
    nvim.buffer.create_highlight(log.NULL_LOGGER, hlgroup .. name, {
      foreground = level.color,
      ctermfg = level.color,
      bold = true,
    })
  end

  return buffer
end

local function prefix(n, char, text)
  local begining = string.rep(char, n)

  local lines = { }
  for line in text:gmatch("([^\n]*)\n?") do
    if line ~= '' then
      table.insert(lines, begining .. '| ' .. line)
    end
  end

  return lines
end

local function raw_log(buffer, name, ns, level, message, data)
  local start_row = nvim.buffer.last_row(buffer)
  local end_row = start_row == 0 and 1 or start_row
  local hlgroup = name .. level

  local lines = { level .. ' ' .. message }
  if data then
    local textlines = prefix(#level - 1, ' ', vim.inspect(data))
    for _, line in ipairs(textlines) do
      table.insert(lines, line)
    end

    table.insert(lines, '')
  end

  nvim.buffer.with_options(log.NULL_LOGGER, buffer, { modifiable = true }, function()
    nvim.buffer.set_lines(log.NULL_LOGGER, buffer, start_row, end_row, true, lines)
  end)

  nvim.buffer.add_highlight(log.NULL_LOGGER, buffer, ns, hlgroup, start_row, 0, #level)
  for row = start_row + 1, start_row + #lines do
    nvim.buffer.add_highlight(log.NULL_LOGGER, buffer, ns, hlgroup, row, #level - 1, #level)
  end

  nvim.window.do_in(buffer, function(window)
    nvim.window.set_cursor(log.NULL_LOGGER, window, {
      row = start_row + #lines,
      column = 0
    })
  end)
end

local function show(buffer)
  local bufname = nvim.buffer.get_name(buffer)
  nvim.execute(log.NULL_LOGGER, 'vertical split ' .. bufname)
  nvim.window.do_in(buffer, function(window)
    nvim.window.set_cursor(log.NULL_LOGGER, window, {
      row = nvim.buffer.last_row(buffer),
      column = 0
    })
  end)
end

function log.logger(hlgroup, ns, level)
  local buffer = create(hlgroup)
  local current_priority = log.LEVELS[level].priority

  local do_log = function(l)
    if log.LEVELS[l].priority > current_priority then
      return do_nothing
    end

    return function(message, data)
      vim.schedule(function()
        raw_log(buffer, hlgroup, ns, l, message, data)
      end)
    end
  end

  return {
    show = function() show(buffer) end,

    error = do_log('ERROR'),
    warn = do_log('WARN'),
    info = do_log('INFO'),
    debug = do_log('DEBUG'),
  }
end

return log
