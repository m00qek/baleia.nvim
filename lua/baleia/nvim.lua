local nvim = {}

local function get_highlights(ns)
  local fn_name, result

  -- this is for older neovim versions
  fn_name = "nvim__get_hl_defs"
  if vim.api[fn_name] then
    result = vim.api[fn_name](ns)
  end

  -- this is for neovim versions > 0.9.0
  fn_name = "nvim_get_hl"
  if vim.api[fn_name] then
    result = vim.api[fn_name](ns, {})
  end

  return {
    undefined = function(hl_name)
      return not result[hl_name]
    end,
  }
end

---@param namespace integer
---@param buffer integer
---@param marks baleia.text.Mark[]
---@param highlights { string: baleia.styles.Highlight }
function nvim.highlight_all(namespace, buffer, marks, highlights)
  vim.schedule(function()
    local hl = get_highlights(0)
    for name, attributes in pairs(highlights) do
      if hl.undefined(name) then
        vim.api.nvim_set_hl(0, name, attributes)
      end
    end
  end)

  vim.schedule(function()
    for _, mark in ipairs(marks) do
      vim.api.nvim_buf_add_highlight(
        buffer,
        namespace,
        mark.highlight,
        mark.line - 1,
        mark.firstcolumn - 1,
        mark.lastcolumn or -1
      )
    end
  end)
end

local function already_active(buffer)
  return vim.api.nvim_buf_call(buffer, function()
    return vim.b["baleia_on_new_lines"]
  end)
end

function nvim.buffer_on_new_lines(buffer, namespace, fn)
  if already_active(buffer) then
    return
  end

  vim.api.nvim_buf_set_var(buffer, "baleia_on_new_lines", true)

  vim.api.nvim_buf_attach(buffer, false, {
    on_bytes = function(_, _, _, start_row, _, _, old_end_row, _, _, new_end_row)
      if vim.api.nvim_buf_line_count(buffer) <= 0 then
        return
      end

      if old_end_row < new_end_row then
        local end_row = start_row + new_end_row

        fn(buffer, namespace, start_row, end_row)
      end
    end,
  })
end

return nvim
