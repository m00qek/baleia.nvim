local win = {}

function win.do_in(buffer, callback)
  local windows = vim.api.nvim_list_wins()

  for _, window in ipairs(windows) do
    if vim.api.nvim_win_get_buf(window) == buffer then
      callback(window)
    end
  end

  return windows
end

function win.set_cursor(_, window, position)
  return vim.api.nvim_win_set_cursor(window, {
    position.row,
    position.column,
  })
end

return win
