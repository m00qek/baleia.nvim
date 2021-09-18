local END_OF_FILE = -1

local nvim = {}

function nvim.get_lines(buffer, startline, endline)
  return vim.api.nvim_buf_get_lines(
    buffer,
    startline - 1,
    endline or END_OF_FILE,
    true)
end

function nvim.create_namespace(name)
  return vim.api.nvim_create_namespace(name)
end

function nvim.execute_on_new_lines(buffer, ns, fn)
  vim.api.nvim_buf_attach(buffer, false, {
    on_bytes = function (_, _, _, start_row, _, _, old_end_row, _, _, new_end_row)
      if old_end_row < new_end_row then
         fn(buffer, ns, start_row + 1, start_row + new_end_row)
      end
    end
  })
end

return nvim
