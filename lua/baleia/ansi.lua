local ansi = {}

ansi.PATTERN = "\x1b[[0-9][:;0-9]*m"

ansi.foreground = {
  [30] =  0,
  [31] =  1,
  [32] =  2,
  [33] =  3,
  [34] =  4,
  [35] =  5,
  [36] =  6,
  [37] =  7,

  -- bright colors below (not ANSI but implemented by aixterm)
  -- see https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
  [90] =  8,
  [91] =  9,
  [92] = 10,
  [93] = 11,
  [94] = 12,
  [95] = 13,
  [96] = 14,
  [97] = 15,
}

ansi.background = {
   [40] =  0,
   [41] =  1,
   [42] =  2,
   [43] =  3,
   [44] =  4,
   [45] =  5,
   [46] =  6,
   [47] =  7,

  -- bright colors below (not ANSI but implemented by aixterm)
  -- see https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
  [100] =  8,
  [101] =  9,
  [102] = 10,
  [103] = 11,
  [104] = 12,
  [105] = 13,
  [106] = 14,
  [107] = 15,
}

ansi.color = {
  set = {
    [38] = 'foreground',
    [48] = 'background',

    -- not ANSI but part of a common kitty extension for underlines
    -- see https://sw.kovidgoyal.net/kitty/underlines/
    [58] = 'special',
  },
  reset = {
    [39] = 'foreground',
    [49] = 'background',

    -- not ANSI but part of a common kitty extension for underlines
    -- see https://sw.kovidgoyal.net/kitty/underlines/
    [59] = 'special',
  }
}

ansi.modes = {
  [22] = { attribute = "bold",          definition = { set = true, value = false, name = 2^0 } },
   [1] = { attribute = "bold",          definition = { set = true, value = true,  name = 2^1 } },

  [23] = { attribute = "italic",        definition = { set = true, value = false, name = 2^2 } },
   [3] = { attribute = "italic",        definition = { set = true, value = true,  name = 2^3 } },

  [24] = { attribute = "underline",     definition = { set = true, value = false, name = 2^4 } },
   [4] = { attribute = "underline",     definition = { set = true, value = true,  name = 2^5 } },

  [27] = { attribute = "reverse",       definition = { set = true, value = false, name = 2^6 } },
   [7] = { attribute = "reverse",       definition = { set = true, value = true,  name = 2^7 } },

  [29] = { attribute = "strikethrough", definition = { set = true, value = false, name = 2^8 } },
   [9] = { attribute = "strikethrough", definition = { set = true, value = true,  name = 2^9 } },
}

-- these are not ANSI but part of a common kitty extension for underlines
-- see https://sw.kovidgoyal.net/kitty/underlines/
ansi.kittymodes = {
  ["4:0"] = { attributes = { "underline", "underdouble", "undercurl", "underdotted", "underdashed" },
              definition = { set = true, value = false, name = 2^10 } },

  ["4:1"] = { attributes = { "underline"   }, definition = { set = true, value = true,  name = 2^11 } },
  ["4:2"] = { attributes = { "underdouble" }, definition = { set = true, value = true,  name = 2^12 } },
  ["4:3"] = { attributes = { "undercurl"   }, definition = { set = true, value = true,  name = 2^13 } },
  ["4:4"] = { attributes = { "underdotted" }, definition = { set = true, value = true,  name = 2^14 } },
  ["4:5"] = { attributes = { "underdashed" }, definition = { set = true, value = true,  name = 2^15 } },
}

return ansi
