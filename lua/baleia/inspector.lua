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

local function style_from_mark(mark)
  local hl_group = mark[4].hl_group
  if not hl_group then
    return {}
  end
  return to_style(vim.api.nvim_get_hl(0, { name = hl_group, link = false }))
end

---@param buffer integer
---@param namespace integer
---@param row integer
---@return baleia.Style
function M.style_at_end_of_line(buffer, namespace, row)
  local extmarks = vim.api.nvim_buf_get_extmarks(buffer, namespace, { row, 0 }, { row, -1 }, { details = true })

  if #extmarks == 0 then
    return {} -- styles.none() equivalent
  end

  local line = vim.api.nvim_buf_get_lines(buffer, row, row + 1, false)[1] or ""
  local eol = #line

  -- A point mark on the column after the last character records the style
  -- carried past the line. A trailing reset has no highlight group.
  for index = #extmarks, 1, -1 do
    local mark = extmarks[index]
    local details = mark[4]
    if not details.end_col and mark[3] >= eol then
      return style_from_mark(mark)
    end
  end

  -- A highlight carries only when it still covers the last column. A reset
  -- followed by plain text leaves that column uncovered.
  local last_col = eol - 1
  if last_col >= 0 then
    for index = #extmarks, 1, -1 do
      local mark = extmarks[index]
      local details = mark[4]
      local end_col = details.end_col
      if end_col and last_col >= mark[3] and last_col < end_col then
        return style_from_mark(mark)
      end
    end
  end

  return {}
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
