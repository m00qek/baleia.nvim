local END_OF_FILE = -1

local ANSI_COLORS = { 'black', 'red', 'green', 'yellow', 'blue', 'magenta',
                      'cyan', 'white' }

local nvim = {}

function nvim.get_lines(buffer, startline, endline)
  if endline then
    endline = endline - 1
  end

  return vim.api.nvim_buf_get_lines(buffer, startline - 1, endline or END_OF_FILE, true)
end

function nvim.create_namespace(name)
  return vim.api.nvim_create_namespace(name)
end

function nvim.execute_on_change(buffer, ns, fn)
  vim.api.nvim_buf_attach(buffer, false, {
    on_lines = function (_, buf, _, firstline, lastline, _, _, _, _)
      fn(buf, ns, firstline + 1, lastline + 1)
    end
  })
end

function nvim.theme_colors()
  local nvim_colors = {}

  for index, color in pairs(ANSI_COLORS) do
    nvim_colors[color] = vim.g['terminal_color_' .. index - 1] or color
  end

  return nvim_colors
end

return nvim
