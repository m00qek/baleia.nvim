local xterm = require("baleia.xterm")

local M = {}

local function hex_to_cterm(hex)
  if not hex then
    return nil
  end
  -- hex is "#RRGGBB"
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  return xterm.from_rgb(r, g, b)
end

local function cterm_to_hex(cterm)
  if not cterm then
    return
  end
  return xterm.to_truecolor(cterm)
end

---Generates a unique name for a style table
---@param prefix string
---@param style baleia.Style
---@return string
function M.name(prefix, style)
  -- We sort keys to ensure deterministic naming
  local parts = { prefix }
  local keys = {}
  for k in pairs(style) do
    table.insert(keys, k)
  end
  table.sort(keys)

  for _, k in ipairs(keys) do
    local val = tostring(style[k]):gsub("#", "x")
    table.insert(parts, k)
    table.insert(parts, val)
  end
  return table.concat(parts, "_")
end

---Hydrates a style table with missing complementary colors
---@param style baleia.Style
---@param theme baleia.ansi.Theme? Optional theme mapping for 16 colors
---@return table
function M.attributes(style, theme)
  local attrs = {}

  -- Copy existing attributes
  for k, v in pairs(style) do
    attrs[k] = v
  end

  -- 1. Handle Foreground
  if attrs.foreground and not attrs.ctermfg then
    attrs.ctermfg = hex_to_cterm(attrs.foreground)
  elseif attrs.ctermfg and not attrs.foreground then
    if theme and theme[attrs.ctermfg] then
      -- If theme provides a name like "DarkRed" or a hex, use it?
      -- The old code used theme mapping. Let's assume theme maps index -> hex/name.
      attrs.foreground = theme[attrs.ctermfg]
    else
      attrs.foreground = cterm_to_hex(attrs.ctermfg)
    end
  end

  -- 2. Handle Background
  if attrs.background and not attrs.ctermbg then
    attrs.ctermbg = hex_to_cterm(attrs.background)
  elseif attrs.ctermbg and not attrs.background then
    if theme and theme[attrs.ctermbg] then
      attrs.background = theme[attrs.ctermbg]
    else
      attrs.background = cterm_to_hex(attrs.ctermbg)
    end
  end

  -- 3. Handle Special (Underline color)
  if attrs.special and not attrs.ctermsp then
    -- Neovim doesn't use ctermsp, so we don't need to generate it from special
    attrs.ctermsp = nil
  elseif attrs.ctermsp and not attrs.special then
    if theme and theme[attrs.ctermsp] then
      attrs.special = theme[attrs.ctermsp]
    else
      attrs.special = cterm_to_hex(attrs.ctermsp)
    end
    attrs.ctermsp = nil
  else
    attrs.ctermsp = nil
  end

  return attrs
end

---Redefines cached highlight groups, e.g. after `:hi clear`
---@param cache { [string]: table }
function M.restore(cache)
  for hl_name, attrs in pairs(cache) do
    vim.api.nvim_set_hl(0, hl_name, attrs)
  end
end

---True when a highlight paints the last column of a full line.
---Marks shifted past `text` belong to a partial edit, not the line end.
---@param item baleia.LexerItem
---@return boolean
local function highlight_covers_end(item)
  local last = #item.text - 1
  if last < 0 then
    return false
  end

  local covered = false
  for _, mark in ipairs(item.highlights) do
    if mark.from > last or mark.to > last then
      return false
    end
    if mark.from <= last and mark.to >= last then
      covered = true
    end
  end
  return covered
end

-- A reset after the last character leaves a highlight covering the end of the
-- line, which would otherwise be read back as the carried style. Park an
-- unhighlighted mark on the following column so that read returns no style.
local function mark_trailing_reset(buffer, namespace, row, item)
  if item.continued ~= false or not highlight_covers_end(item) then
    return
  end

  local current = vim.api.nvim_buf_get_lines(buffer, row, row + 1, false)[1] or ""
  if #current ~= #item.text then
    return
  end

  vim.api.nvim_buf_set_extmark(buffer, namespace, row, #current, {
    right_gravity = false,
  })
end

---@param buffer integer
---@param namespace integer
---@param start_row integer
---@param items baleia.LexerItem[]
---@param options baleia.Options
---@param update_text boolean?
function M.render(buffer, namespace, start_row, items, options, update_text)
  options.highlight_cache = options.highlight_cache or {}
  local cache = options.highlight_cache

  if update_text then
    local texts = {}
    for i, item in ipairs(items) do
      texts[i] = item.text
    end
    vim.api.nvim_buf_set_lines(buffer, start_row, start_row + #items, false, texts)
  end

  for i, item in ipairs(items) do
    local row = start_row + i - 1

    for _, mark in ipairs(item.highlights) do
      -- The style from lexer is the "raw" style.
      -- We name it based on its raw properties to avoid re-calculating hydration if seen before.
      local hl_name = M.name(options.name, mark.style)

      if not cache[hl_name] then
        local attrs = M.attributes(mark.style, options.colors)
        vim.api.nvim_set_hl(0, hl_name, attrs)
        cache[hl_name] = attrs
      end

      vim.api.nvim_buf_set_extmark(buffer, namespace, row, mark.from, {
        end_col = mark.to + 1,
        hl_group = hl_name,
      })
    end

    mark_trailing_reset(buffer, namespace, row, item)
  end
end

return M
