local xterm = require("baleia.xterm")

local M = {}

---@param hex string
---@return integer
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

---@param cterm integer
---@return string
local function cterm_to_hex(cterm)
  if not cterm then
    return
  end
  return xterm.to_truecolor(cterm)
end

---Generates a unique name for a style table
---@param prefix string
---@param style table
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
---@param style table
---@param theme table? Optional theme mapping for 16 colors
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
    -- xterm.lua doesn't explicitly support converting special to ctermsp in `from_rgb` context easily
    -- but ctermsp is usually just a color index.
    attrs.ctermsp = hex_to_cterm(attrs.special)
  elseif attrs.ctermsp and not attrs.special then
    attrs.special = cterm_to_hex(attrs.ctermsp)
  end

  return attrs
end

---@param buffer integer
---@param namespace integer
---@param start_row integer
---@param items baleia.LexerItem[]
---@param options baleia.options.Basic
---@param update_text boolean?
function M.render(buffer, namespace, start_row, items, options, update_text)
  options.highlight_cache = options.highlight_cache or {}
  local cache = options.highlight_cache

  for i, item in ipairs(items) do
    local row = start_row + i - 1

    if update_text then
      vim.api.nvim_buf_set_lines(buffer, row, row + 1, false, { item.text })
    end

    for _, mark in ipairs(item.highlights) do
      -- The style from lexer is the "raw" style.
      -- We name it based on its raw properties to avoid re-calculating hydration if seen before.
      local hl_name = M.name(options.name, mark.style)

      if not cache[hl_name] then
        local attrs = M.attributes(mark.style, options.colors)
        vim.api.nvim_set_hl(0, hl_name, attrs)
        cache[hl_name] = true
      end

      vim.api.nvim_buf_add_highlight(buffer, namespace, hl_name, row, mark.from, mark.to + 1)
    end
  end
end

return M
