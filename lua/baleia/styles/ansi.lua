local colors = require("baleia.styles.colors")
local modes = require("baleia.styles.modes")

---@class baleia.styles.attributes.Generator
---@field params integer
---@field fn { [string]: fun(...: integer): (baleia.styles.attributes.Mode | baleia.styles.attributes.Color) }

---@class baleia.styles.attributes.definition.Generator
---@field generators { [integer]: baleia.styles.attributes.Generator }

---@class baleia.styles.attributes.definition.Mode
---@field definition { [string]: baleia.styles.attributes.Mode }

---@class baleia.styles.attributes.definition.Color
---@field definition { [string]: baleia.styles.attributes.Color }

local M = {}

-- selene: allow(bad_string_escape) because it does not recognize \x1b
---@type string
M.PATTERN = "\x1b[[0-9]?[:;0-9]*m"

---@type { [integer]: baleia.styles.attributes.definition.Color | baleia.styles.attributes.definition.Generator }
M.colors = {
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
    },
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
    },
  },
  [49] = { definition = { background = colors.reset() } },

  -- bright colors below (not ANSI but implemented by aixterm)
  -- see https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
  [90] = { definition = { foreground = colors.from_xterm(8) } },
  [91] = { definition = { foreground = colors.from_xterm(9) } },
  [92] = { definition = { foreground = colors.from_xterm(10) } },
  [93] = { definition = { foreground = colors.from_xterm(11) } },
  [94] = { definition = { foreground = colors.from_xterm(12) } },
  [95] = { definition = { foreground = colors.from_xterm(13) } },
  [96] = { definition = { foreground = colors.from_xterm(14) } },
  [97] = { definition = { foreground = colors.from_xterm(15) } },

  [100] = { definition = { background = colors.from_xterm(8) } },
  [101] = { definition = { background = colors.from_xterm(9) } },
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
    },
  },
  [59] = { definition = { special = colors.reset() } },
}

---@type { [integer|string]: baleia.styles.attributes.definition.Mode }
M.modes = {
  [22] = { definition = { bold = modes.turn_off(2 ^ 0) } },
  [01] = { definition = { bold = modes.turn_on(2 ^ 1) } },

  [23] = { definition = { italic = modes.turn_off(2 ^ 2) } },
  [03] = { definition = { italic = modes.turn_on(2 ^ 3) } },

  [27] = { definition = { reverse = modes.turn_off(2 ^ 4) } },
  [07] = { definition = { reverse = modes.turn_on(2 ^ 5) } },

  [29] = { definition = { strikethrough = modes.turn_off(2 ^ 6) } },
  [09] = { definition = { strikethrough = modes.turn_on(2 ^ 7) } },

  [24] = {
    definition = {
      underline = modes.turn_off(2 ^ 8),
      underdouble = modes.turn_off(2 ^ 8),
      undercurl = modes.turn_off(2 ^ 8),
      underdotted = modes.turn_off(2 ^ 8),
      underdashed = modes.turn_off(2 ^ 8),
    },
  },
  [04] = { definition = { underline = modes.turn_on(2 ^ 9) } },

  -- these are not ANSI but part of a common kitty extension for underlines
  -- see https://sw.kovidgoyal.net/kitty/underlines/
  ["4:0"] = {
    definition = {
      underline = modes.turn_off(2 ^ 8),
      underdouble = modes.turn_off(2 ^ 8),
      undercurl = modes.turn_off(2 ^ 8),
      underdotted = modes.turn_off(2 ^ 8),
      underdashed = modes.turn_off(2 ^ 8),
    },
  },

  ["4:1"] = { definition = { underline = modes.turn_on(2 ^ 9) } },
  ["4:2"] = { definition = { underdouble = modes.turn_on(2 ^ 10) } },
  ["4:3"] = { definition = { undercurl = modes.turn_on(2 ^ 11) } },
  ["4:4"] = { definition = { underdotted = modes.turn_on(2 ^ 12) } },
  ["4:5"] = { definition = { underdashed = modes.turn_on(2 ^ 13) } },
}

return M
