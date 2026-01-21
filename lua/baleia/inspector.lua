local styles = require("baleia.styles")

local M = {}

---@param buffer integer
---@param namespace integer
---@param row integer
---@return baleia.styles.Style
function M.style_at_end_of_line(buffer, namespace, row)
  local extmarks = vim.api.nvim_buf_get_extmarks(
    buffer,
    namespace,
    { row, 0 },
    { row, -1 },
    { details = true }
  )

  if #extmarks == 0 then
    return styles.none()
  end

  local last_mark = extmarks[#extmarks]
  local details = last_mark[4]
  local hl_group = details.hl_group

  return styles.from_name(hl_group)
end

---@param buffer integer
---@param namespace integer
---@param row integer
---@param col integer
---@return baleia.styles.Style
function M.style_at(buffer, namespace, row, col)
  local extmarks = vim.api.nvim_buf_get_extmarks(
    buffer,
    namespace,
    { row, 0 },
    { row, -1 },
    { details = true }
  )

  for _, mark in ipairs(extmarks) do
    local start_col = mark[3]
    local end_col = mark[4].end_col
    if col >= start_col and col < end_col then
      return styles.from_name(mark[4].hl_group)
    end
  end

  return styles.none()
end

return M