local END_OF_LINE = -1
local END_OF_FILE = -1

local nvim = {}

function nvim.create_highlight(name, attributes)
  local command = 'highlight ' .. name

  if attributes.cterm then
      command = command .. ' cterm=' .. table.concat(attributes.cterm, ',')
  end

  attributes.cterm = nil
  for attr, value in pairs(attributes) do
    if value then
      command = command .. ' ' .. attr .. '=' .. value
    end
  end

  return vim.api.nvim_command(command)
end

function nvim.get_lines(buffer, startline, endline)
  if endline then
    endline = endline - 1
  end

  return vim.api.nvim_buf_get_lines(buffer, startline - 1, endline or END_OF_FILE, true)
end

function nvim.create_namespace(name)
  return vim.api.nvim_create_namespace(name)
end 

function nvim.highlight(buffer, ns, name, position)
  local lastcolumn = END_OF_LINE
  if position.lastcolumn then
    lastcolumn = position.lastcolumn - 1
  end

  return vim.api.nvim_buf_add_highlight(
    buffer, ns, name, position.line - 1, position.firstcolumn - 1, lastcolumn)
end

function nvim.execute_on_change(buffer, ns, fn)
  vim.api.nvim_buf_attach(buffer, false, { 
    on_lines = function (_, buf, _, firstline, lastline, _, _, _, _)
      fn(buf, ns, firstline + 1, lastline + 1)
    end
  })
end

local ansi_colors = { 'black', 'red', 'green', 'yellow', 'blue', 'magenta',
                      'cyan', 'white' }  

function nvim.theme_colors()
  local nvim_colors = {}

  for index, color in pairs(ansi_colors) do
    nvim_colors[color] = vim.g['terminal_color_' .. index - 1] or color
  end

  return nvim_colors
end

return nvim
