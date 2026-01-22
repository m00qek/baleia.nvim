M = {}

M.PATTERN = "\x1b[[0-9]?[:;0-9]*m"

local function reset()
  return function(style)
    for attr in pairs(style) do
      style[attr] = nil
    end
  end
end

local function unset(...)
  local attrs = { ... }
  return function(style)
    for _, attr in ipairs(attrs) do
      style[attr] = nil
    end
  end
end

local function set(attr, fn)
  if not fn then
    return function(style)
      style[attr] = true
    end
  end

  return function(style, iterator)
    style[attr] = fn(iterator)
  end
end

local function xterm(code)
  return function(iterator)
    if code then
      return code
    end
    local val = iterator()
    return tonumber(val)
  end
end

local function rgb()
  return function(iterator)
    local r, g, b = tonumber(iterator()), tonumber(iterator()), tonumber(iterator())
    return string.format("#%02x%02x%02x", r, g, b)
  end
end

local function iter(ansi_sequence)
  if not ansi_sequence:find("[0-9]") then
    local done = false
    return function()
      if not done then
        done = true
        return "0"
      end
      return nil
    end
  end
  return ansi_sequence:gmatch("[:0-9]+")
end

function M.apply(ansi_sequence, base_style)
  local style = base_style or {}
  local root = M.declarations
  local node = root

  local iterator = iter(ansi_sequence)
  local token = iterator()

  while token do
    local code = tonumber(token) or token
    local next_node = node[code]

    if next_node then
      node = next_node
      if type(node) == "function" then
        node(style, iterator)
        node = root
      end
    else
      node = root
    end

    token = iterator()
  end

  return style
end

function M.clone(style)
  local style_clone = {}
  for attr, value in pairs(style) do
    style_clone[attr] = value
  end

  return style_clone
end

M.declarations = {
  [00] = reset(),

  [01] = set("bold"),
  [22] = unset("bold"),

  [03] = set("italic"),
  [23] = unset("italic"),

  [09] = set("strikethrough"),
  [29] = unset("strikethrough"),

  [07] = set("reverse"),
  [27] = unset("reverse"),

  [04] = set("underline"),
  [24] = unset("underline", "undercurl", "underdouble", "underdotted", "underdashed"), -- Clears ALL underlines

  [30] = set("ctermfg", xterm(0)),
  [31] = set("ctermfg", xterm(1)),
  [32] = set("ctermfg", xterm(2)),
  [33] = set("ctermfg", xterm(3)),
  [34] = set("ctermfg", xterm(4)),
  [35] = set("ctermfg", xterm(5)),
  [36] = set("ctermfg", xterm(6)),
  [37] = set("ctermfg", xterm(7)),
  [38] = {
    [2] = set("foreground", rgb()),
    [5] = set("ctermfg", xterm()),
  },
  [39] = unset("ctermfg", "foreground"),

  [40] = set("ctermbg", xterm(0)),
  [41] = set("ctermbg", xterm(1)),
  [42] = set("ctermbg", xterm(2)),
  [43] = set("ctermbg", xterm(3)),
  [44] = set("ctermbg", xterm(4)),
  [45] = set("ctermbg", xterm(5)),
  [46] = set("ctermbg", xterm(6)),
  [47] = set("ctermbg", xterm(7)),
  [48] = {
    [2] = set("background", rgb()),
    [5] = set("ctermbg", xterm()),
  },
  [49] = unset("ctermbg", "background"),

  -- bright colors below (not ANSI but implemented by aixterm)
  -- see https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
  [90] = set("ctermfg", xterm(8)),
  [91] = set("ctermfg", xterm(9)),
  [92] = set("ctermfg", xterm(10)),
  [93] = set("ctermfg", xterm(11)),
  [94] = set("ctermfg", xterm(12)),
  [95] = set("ctermfg", xterm(13)),
  [96] = set("ctermfg", xterm(14)),
  [97] = set("ctermfg", xterm(15)),

  [100] = set("ctermbg", xterm(8)),
  [101] = set("ctermbg", xterm(9)),
  [102] = set("ctermbg", xterm(10)),
  [103] = set("ctermbg", xterm(11)),
  [104] = set("ctermbg", xterm(12)),
  [105] = set("ctermbg", xterm(13)),
  [106] = set("ctermbg", xterm(14)),
  [107] = set("ctermbg", xterm(15)),

  -- these are not ANSI but part of a common kitty extension for underlines
  -- see https://sw.kovidgoyal.net/kitty/underlines/
  [58] = {
    [2] = set("special", rgb()),
    [5] = set("ctermsp", xterm()),
  },
  [59] = unset("ctermsp", "special"),

  ["4:0"] = unset("underline", "undercurl", "underdouble", "underdotted", "underdashed"),
  ["4:1"] = set("underline"),
  ["4:2"] = set("underdouble"),
    ["4:3"] = set("undercurl"),
    ["4:4"] = set("underdotted"),
    ["4:5"] = set("underdashed"),
  }
  
  ---@alias baleia.styles.Theme { [integer]: string }
  
  ---@type baleia.styles.Theme
  M.NR_16 = {
    [00] = "Black",
    [01] = "DarkBlue",
    [02] = "DarkGreen",
    [03] = "DarkCyan",
    [04] = "DarkRed",
    [05] = "DarkMagenta",
    [06] = "DarkYellow",
    [07] = "LightGrey",
    [08] = "DarkGrey",
    [09] = "LightBlue",
    [10] = "LightGreen",
    [11] = "LightCyan",
    [12] = "LightRed",
    [13] = "LightMagenta",
    [14] = "LightYellow",
    [15] = "White",
  }
  
  ---@type baleia.styles.Theme
  M.NR_8 = {
    [00] = "Black",
    [01] = "DarkRed",
    [02] = "DarkGreen",
    [03] = "DarkYellow",
    [04] = "DarkBlue",
    [05] = "DarkMagenta",
    [06] = "DarkCyan",
    [07] = "LightGrey",
    [08] = "DarkGrey",
    [09] = "LightRed",
    [10] = "LightGreen",
    [11] = "LightYellow",
    [12] = "LightBlue",
    [13] = "LightMagenta",
    [14] = "LightCyan",
    [15] = "White",
  }
  
  return M
