local styles = require("baleia.styles")

local M = {}

---@param buffer integer
---@param namespace integer
---@param start_row integer
---@param items baleia.LexerItem[]
---@param options baleia.options.Basic
---@param update_text boolean?
function M.render(buffer, namespace, start_row, items, options, update_text)
  -- Initialize cache if it doesn't exist
  -- We attach it to options to persist across chunks/calls for this baleia instance
  options.highlight_cache = options.highlight_cache or {}
  local cache = options.highlight_cache

  for i, item in ipairs(items) do
    local row = start_row + i - 1

    if update_text then
      vim.api.nvim_buf_set_lines(buffer, row, row + 1, false, { item.text })
    end

    for _, mark in ipairs(item.highlights) do
      local hl_name = styles.name(options.name, mark.style)

      if not cache[hl_name] then
        local attrs = styles.attributes(mark.style, options.colors)
        vim.api.nvim_set_hl(0, hl_name, attrs)
        cache[hl_name] = true
      end

      vim.api.nvim_buf_add_highlight(buffer, namespace, hl_name, row, mark.from, mark.to + 1)
    end
  end
end

return M
