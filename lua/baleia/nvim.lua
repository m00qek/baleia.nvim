local END_OF_FILE = -1

local nvim = {}

function nvim.get_lines(buffer, startline, endline)
  if endline then
    endline = endline - 1
  end

  return vim.api.nvim_buf_get_lines(
    buffer,
    startline - 1,
    endline or END_OF_FILE,
    true)
end

function nvim.create_namespace(name)
  return vim.api.nvim_create_namespace(name)
end

function nvim.execute_on_change(buffer, ns, fn)
  vim.api.nvim_buf_attach(buffer, false, {
    on_lines = function (_, buf, _, firstline, lastline)
      vim.api.nvim_buf_set_var(buffer, 'baleia_colorizing', true)
      fn(buf, ns, firstline + 1, lastline + 1)
      vim.api.nvim_buf_set_var(buffer, 'baleia_colorizing', false)
    end
  })
end

return nvim
