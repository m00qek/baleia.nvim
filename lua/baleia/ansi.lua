local colors = require("baleia.colors")

local ansi = {}

ansi.PATTERN = "\x1b[[0-9][:;0-9]*m"

ansi.colors = {
  [30] = { definition = { foreground = colors.from_xterm(0) } },
  [31] = { definition = { foreground = colors.from_xterm(1) } },
  [32] = { definition = { foreground = colors.from_xterm(2) } },
  [33] = { definition = { foreground = colors.from_xterm(3) } },
  [34] = { definition = { foreground = colors.from_xterm(4) } },
  [35] = { definition = { foreground = colors.from_xterm(5) } },
  [36] = { definition = { foreground = colors.from_xterm(6) } },
  [37] = { definition = { foreground = colors.from_xterm(7) } },
  [38] = {
    generators = {
      [5] = { params = 1, fn = { foreground = colors.from_xterm } },
      [2] = { params = 3, fn = { foreground = colors.from_truecolor } },
    }
  },
  [39] = { definition = { foreground = colors.reset() } },

  [40] = { definition = { background = colors.from_xterm(0) } },
  [41] = { definition = { background = colors.from_xterm(1) } },
  [42] = { definition = { background = colors.from_xterm(2) } },
  [43] = { definition = { background = colors.from_xterm(3) } },
  [44] = { definition = { background = colors.from_xterm(4) } },
  [45] = { definition = { background = colors.from_xterm(5) } },
  [46] = { definition = { background = colors.from_xterm(6) } },
  [47] = { definition = { background = colors.from_xterm(7) } },
  [48] = {
    generators = {
      [5] = { params = 1, fn = { background = colors.from_xterm } },
      [2] = { params = 3, fn = { background = colors.from_truecolor } },
    }
  },
  [49] = { definition = { background = colors.reset() } },

  -- bright colors below (not ANSI but implemented by aixterm)
  -- see https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
  [90] = { definition = { foreground = colors.from_xterm( 8) } },
  [91] = { definition = { foreground = colors.from_xterm( 9) } },
  [92] = { definition = { foreground = colors.from_xterm(10) } },
  [93] = { definition = { foreground = colors.from_xterm(11) } },
  [94] = { definition = { foreground = colors.from_xterm(12) } },
  [95] = { definition = { foreground = colors.from_xterm(13) } },
  [96] = { definition = { foreground = colors.from_xterm(14) } },
  [97] = { definition = { foreground = colors.from_xterm(15) } },

  [100] = { definition = { background = colors.from_xterm( 8) } },
  [101] = { definition = { background = colors.from_xterm( 9) } },
  [102] = { definition = { background = colors.from_xterm(10) } },
  [103] = { definition = { background = colors.from_xterm(11) } },
  [104] = { definition = { background = colors.from_xterm(12) } },
  [105] = { definition = { background = colors.from_xterm(13) } },
  [106] = { definition = { background = colors.from_xterm(14) } },
  [107] = { definition = { background = colors.from_xterm(15) } },

  -- not ANSI but part of a common kitty extension for underlines
  -- see https://sw.kovidgoyal.net/kitty/underlines/
  [58] = {
    generators = {
      [5] = { params = 1, fn = { special = colors.from_xterm } },
      [2] = { params = 3, fn = { special = colors.from_truecolor } },
    }
  },
  [59] = { definition = { special = colors.reset() } },
}

ansi.modes = {
  [22] = { definition = { bold = { set = true, value = false, name = 2^0 } } },
   [1] = { definition = { bold = { set = true, value = true,  name = 2^1 } } },

  [23] = { definition = { italic = { set = true, value = false, name = 2^2 } } },
   [3] = { definition = { italic = { set = true, value = true,  name = 2^3 } } },

  [24] = { definition = { underline = { set = true, value = false, name = 2^4 } } },
   [4] = { definition = { underline = { set = true, value = true,  name = 2^5 } } },

  [27] = { definition = { reverse = { set = true, value = false, name = 2^6 } } },
   [7] = { definition = { reverse = { set = true, value = true,  name = 2^7 } } },

  [29] = { definition = { strikethrough = { set = true, value = false, name = 2^8 } } },
   [9] = { definition = { strikethrough = { set = true, value = true, name = 2^9 } } },

-- these are not ANSI but part of a common kitty extension for underlines
-- see https://sw.kovidgoyal.net/kitty/underlines/
  ["4:0"] = {
    definition = {
      underline   = { set = true, value = false, name = 2^10 },
      underdouble = { set = true, value = false, name = 2^10 },
      undercurl   = { set = true, value = false, name = 2^10 },
      underdotted = { set = true, value = false, name = 2^10 },
      underdashed = { set = true, value = false, name = 2^10 },
    },
  },

  ["4:1"] = { definition = { underline   = { set = true, value = true, name = 2^4 } } },
  ["4:2"] = { definition = { underdouble = { set = true, value = true, name = 2^12 } } },
  ["4:3"] = { definition = { undercurl   = { set = true, value = true, name = 2^13 } } },
  ["4:4"] = { definition = { underdotted = { set = true, value = true, name = 2^14 } } },
  ["4:5"] = { definition = { underdashed = { set = true, value = true, name = 2^15 } } },
}

return ansi
