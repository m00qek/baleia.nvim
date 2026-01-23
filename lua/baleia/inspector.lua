local M = {}

local function int_to_hex(color)
  if not color then
    return nil
  end
  return string.format("#%06x", color)
end

local function to_style(hl)
  local style = {}

  -- Colors
  if hl.fg then
    style.foreground = int_to_hex(hl.fg)
  end
  if hl.bg then
    style.background = int_to_hex(hl.bg)
  end
  if hl.sp then
    style.special = int_to_hex(hl.sp)
  end

  if hl.ctermfg then
    style.ctermfg = hl.ctermfg
  end
  if hl.ctermbg then
    style.ctermbg = hl.ctermbg
  end

  -- List from standard attributes we support
  local attrs = {
    "bold",
    "italic",
    "underline",
    "undercurl",
    "underdouble",
    "underdotted",
    "underdashed",
    "strikethrough",
    "reverse",
  }

  for _, attr in ipairs(attrs) do
    if hl[attr] then
      style[attr] = true
    end
  end

  return style
end

---@param buffer integer
---@param namespace integer
---@param row integer
---@return baleia.Style
function M.style_at_end_of_line(buffer, namespace, row)
  -- We want the LAST mark on the line
  local extmarks = vim.api.nvim_buf_get_extmarks(buffer, namespace, { row, 0 }, { row, -1 }, { details = true })

  if #extmarks == 0 then
    return {} -- styles.none() equivalent
  end

  local last_mark = extmarks[#extmarks]
  local hl_group = last_mark[4].hl_group

  if not hl_group then
    return {}
  end

  local hl_def = vim.api.nvim_get_hl(0, { name = hl_group, link = false })
  return to_style(hl_def)
end

---@param buffer integer
---@param namespace integer
---@param row integer
---@param col integer
---@return baleia.Style
function M.style_at(buffer, namespace, row, col)
  local extmarks = vim.api.nvim_buf_get_extmarks(buffer, namespace, { row, 0 }, { row, -1 }, { details = true })

  for _, mark in ipairs(extmarks) do
    local start_col = mark[3]
    local end_col = mark[4].end_col
    if col >= start_col and col < end_col then
      local hl_group = mark[4].hl_group
      if hl_group then
        local hl_def = vim.api.nvim_get_hl(0, { name = hl_group, link = false })
        return to_style(hl_def)
      end
    end
  end

  return {}
end

return M
