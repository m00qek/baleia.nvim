local M = {}

local function scan(str, pos)
  local start_idx, end_idx = string.find(str, "[:0-9]+", pos)
  if not start_idx then
    return nil, pos
  end
  return string.sub(str, start_idx, end_idx), end_idx + 1
end

local function reset()
  return function(style, _, pos)
    for attr in pairs(style) do
      style[attr] = nil
    end
    return pos
  end
end

local function unset(...)
  local attrs = { ... }
  return function(style, _, pos)
    for _, attr in ipairs(attrs) do
      style[attr] = nil
    end
    return pos
  end
end

local function set(attr, fn)
  if not fn then
    return function(style, _, pos)
      style[attr] = true
      return pos
    end
  end

  return function(style, str, pos)
    local val, new_pos = fn(str, pos)
    style[attr] = val
    return new_pos
  end
end

local function xterm(code)
  return function(str, pos)
    if code then
      return code, pos
    end
    local val, new_pos = scan(str, pos)
    return tonumber(val), new_pos
  end
end

local function rgb()
  return function(str, pos)
    local r_val, pos = scan(str, pos)
    local g_val, pos = scan(str, pos)
    local b_val, pos = scan(str, pos)

    local r, g, b = tonumber(r_val), tonumber(g_val), tonumber(b_val)

    if r and g and b then
      return string.format("#%02x%02x%02x", r, g, b), pos
    end
    return nil, pos
  end
end

M.PATTERN = "\x1b%[[:;0-9]*m"

function M.strip(input)
  if type(input) == "string" then
    return (string.gsub(input, M.PATTERN, ""))
  end

  local stripped = {}
  for _, line in ipairs(input) do
    table.insert(stripped, (string.gsub(line, M.PATTERN, "")))
  end
  return stripped
end

function M.apply(ansi_sequence, base_style)
  local style = base_style or {}

  -- Optimization: If no digits, it's a clear/reset sequence (e.g. \x1b[m)
  if not string.find(ansi_sequence, "[0-9]") then
    -- 0 is the reset code
    M.declarations[0](style, ansi_sequence, 1)
    return style
  end

  local root = M.declarations
  local node = root
  local cursor = 1

  while true do
    local token, next_cursor = scan(ansi_sequence, cursor)
    if not token then
      break
    end

    -- Advance cursor past this token
    cursor = next_cursor

    local code = tonumber(token) or token
    local next_node = node[code]

    if next_node then
      node = next_node
      if type(node) == "function" then
        -- Execute node. It may consume more tokens from the string.
        -- We pass the CURRENT cursor. The node returns the NEW cursor.
        cursor = node(style, ansi_sequence, cursor)
        node = root
      end
    else
      node = root
    end
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
  [24] = unset("underline", "undercurl", "underdouble", "underdotted", "underdashed"),

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
