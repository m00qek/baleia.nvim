local styles = require("baleia.styles")

local M = {}

---@param buffer integer
---@param namespace integer
---@param start_row integer
---@param lexer_items baleia.LexerItem[]
---@param options baleia.options.Basic
---@param update_text boolean?
function M.render(buffer, namespace, start_row, lexer_items, options, update_text)
  for i, item in ipairs(lexer_items) do
    local row = start_row + i - 1

    if update_text then
      vim.api.nvim_buf_set_lines(buffer, row, row + 1, false, { item.text })
    end

    for _, mark in ipairs(item.highlights) do
      local hl_name = styles.name(options.name, mark.style)

      local attrs = styles.attributes(mark.style, options.colors)
      vim.api.nvim_set_hl(0, hl_name, attrs)

      vim.api.nvim_buf_add_highlight(buffer, namespace, hl_name, row, mark.from, mark.to + 1)
    end
  end
end

return M
