local ansi = require("baleia.styles.ansi")
local colors = require("baleia.styles.colors")
local modes = require("baleia.styles.modes")

---@class baleia.styles.Style
---@field background baleia.styles.attributes.Color
---@field foreground baleia.styles.attributes.Color
---@field special baleia.styles.attributes.Color
---@field modes { [string]: baleia.styles.attributes.Mode }
---@field offset? integer

---@class baleia.styles.Highlight
---@field foreground? string
---@field background? string
---@field special? string
---@field ctermfg? string
---@field ctermbg? string
---@field bold? boolean
---@field standout? boolean
---@field underline? boolean
---@field undercurl? boolean
---@field underdouble? boolean
---@field underdotted? boolean
---@field underdashed? boolean
---@field strikethrough? boolean
---@field italic? boolean
---@field reverse? boolean

local M = {}

M.ANSI_CODES_PATTERN = ansi.PATTERN

local function merge_value(from, to)
  if to.set then
    return to
  end
  return from
end

---@param from baleia.styles.Style
---@param to baleia.styles.Style
---@return baleia.styles.Style
function M.merge(from, to)
  local style = {
    foreground = merge_value(from.foreground, to.foreground),
    background = merge_value(from.background, to.background),
    special = merge_value(from.special, to.special),
    offset = to.offset or from.offset,
    modes = {},
  }

  for name, attr in pairs(from.modes) do
    style.modes[name] = attr
  end

  for name, attr in pairs(to.modes) do
    style.modes[name] = merge_value(from.modes[name], attr)
  end

  return style
end

---@return baleia.styles.Style
function M.none()
  ---@type baleia.styles.Style
  local style = {
    foreground = colors.none(),
    background = colors.none(),
    special = colors.none(),
    offset = nil,
    modes = {},
  }

  ---TODO: WTF
  for _, mode in pairs(ansi.modes) do
    for name, attr in pairs(mode.definition) do
      if style.modes[name] == nil then
        style.modes[name] = modes.ignore(attr.value.tag)
      end
    end
  end

  return style
end

---@param offset integer
---@return baleia.styles.Style
function M.reset(offset)
  ---@type baleia.styles.Style
  local style = {
    foreground = colors.reset(),
    background = colors.reset(),
    special = colors.reset(),
    offset = offset,
    modes = {},
  }

  for _, mode in pairs(ansi.modes) do
    for name, attr in pairs(mode.definition) do
      if style.modes[name] == nil or style.modes[name].value.tag > attr.value.tag then
        style.modes[name] = modes.turn_off(attr.value.tag)
      end
    end
  end

  return style
end

---@param ansi_sequence string
---@return baleia.styles.Style
function M.to_style(ansi_sequence)
  local codes = {}
  for code in ansi_sequence:gmatch("[:0-9]+") do
    table.insert(codes, tonumber(code) or code)
  end

  -- Empty codes (e.g., \x1b[m) is equivalent to reset (\x1b[0m)
  if #codes == 0 then
    return M.reset(#ansi_sequence)
  end

  local style = M.none()
  local index = 1
  while index <= #codes do
    if codes[index] == 0 then
      style = M.reset(#ansi_sequence)
    elseif ansi.colors[codes[index]] then
      local entry = ansi.colors[codes[index]]

      if entry.definition then
        for attr, value in pairs(entry.definition) do
          style[attr] = value
        end
      elseif entry.generators then
        local flag = codes[index + 1]
        local generator = entry.generators[flag]

        local params = {}
        for i = 1, generator.params, 1 do
          params[i] = codes[index + 1 + i]
        end

        for attr, fn in pairs(generator.fn) do
          style[attr] = fn(unpack(params))
        end

        -- current index + 1 flag + N parameters
        index = index + 1 + generator.params
      end
    elseif ansi.modes[codes[index]] then
      local mode = ansi.modes[codes[index]]
      for name, attr in pairs(mode.definition) do
        style.modes[name] = attr
      end
    end

    index = index + 1
  end

  style.offset = #ansi_sequence
  return style
end

---@param prefix string
---@param style baleia.styles.Style
---@return string
function M.name(prefix, style)
  local modename = 0
  for _, attr in pairs(style.modes) do
    if attr.set then
      modename = bit.bor(modename, attr.value.tag)
    end
  end

  return prefix
    .. "_"
    .. modename
    .. "_"
    .. style.foreground.value.name
    .. "_"
    .. style.background.value.name
    .. "_"
    .. style.special.value.name
end

local tag_to_mode = {}
for _, mode_def in pairs(ansi.modes) do
  for attr_name, attr_val in pairs(mode_def.definition) do
    tag_to_mode[attr_val.value.tag] = { name = attr_name, enabled = attr_val.value.enabled }
  end
end

local function color_from_name(name)
  if name == "none" then
    return colors.none()
  end
  if name:match("^[0-9]+$") then
    return colors.from_xterm(tonumber(name))
  end
  if name:match("^[0-9a-f]+$") and #name == 6 then
    local r = tonumber(name:sub(1, 2), 16)
    local g = tonumber(name:sub(3, 4), 16)
    local b = tonumber(name:sub(5, 6), 16)
    return colors.from_truecolor(r, g, b)
  end
  return colors.none()
end

---@param name string
---@return baleia.styles.Style
function M.from_name(name)
  local parts = {}
  for part in name:gmatch("[^_]+") do
    table.insert(parts, part)
  end

  -- Format: prefix_modename_fg_bg_sp
  -- We assume prefix is "BaleiaColors" or similar, but the split might handle it.
  -- Actually, prefix can contain underscores? "Baleia_Colors"?
  -- The function name(prefix, style) does: prefix .. "_" .. modename ...
  -- So we should probably count from the END.
  -- sp = parts[#parts]
  -- bg = parts[#parts-1]
  -- fg = parts[#parts-2]
  -- modename = parts[#parts-3]

  local sp_name = parts[#parts]
  local bg_name = parts[#parts - 1]
  local fg_name = parts[#parts - 2]
  local modename = tonumber(parts[#parts - 3])

  local style = {
    foreground = color_from_name(fg_name),
    background = color_from_name(bg_name),
    special = color_from_name(sp_name),
    modes = {},
    offset = nil,
  }

  -- Reconstruct modes
  if modename then
    for tag, mode in pairs(tag_to_mode) do
      if bit.band(modename, tag) ~= 0 then
        style.modes[mode.name] = {
          set = true,
          value = { enabled = mode.enabled, tag = tag },
        }
      end
    end
  end

  return style
end

---@param style baleia.styles.Style
---@param theme baleia.styles.Theme
---@return baleia.styles.Highlight
function M.attributes(style, theme)
  ---@type baleia.styles.Highlight
  local attributes = {}

  for name, attr in pairs(style.modes) do
    if attr.set then
      attributes[name] = attr.value.enabled
    end
  end

  if style.foreground.set then
    local color = style.foreground.value
    attributes.ctermfg = colors.cterm(color)
    attributes.foreground = colors.gui(color, theme)
  end

  if style.background.set then
    local color = style.background.value
    attributes.ctermbg = colors.cterm(color)
    attributes.background = colors.gui(color, theme)
  end

  if style.special.set then
    local color = style.special.value
    attributes.special = colors.gui(color, theme)
  end

  return attributes
end

return M
