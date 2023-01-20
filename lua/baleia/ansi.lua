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
  [39] =  'none',
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
   [49] =  'none',
  [100] =  8,
  [101] =  9,
  [102] = 10,
  [103] = 11,
  [104] = 12,
  [105] = 13,
  [106] = 14,
  [107] = 15,
}

-- the last ones are not ANSI but they use a common kitty extension for
-- underlines
ansi.modes = {
  [1]     =  { attribute = "bold",          definition = { set = true, value = true, name = 2^0 } },
  [3]     =  { attribute = "italic",        definition = { set = true, value = true, name = 2^1 } },
  [7]     =  { attribute = "reverse",       definition = { set = true, value = true, name = 2^2 } },
  [9]     =  { attribute = "strikethrough", definition = { set = true, value = true, name = 2^3 } },
  [4]     =  { attribute = "underline",     definition = { set = true, value = true, name = 2^4 } },
  ["4:1"] =  { attribute = "underline",     definition = { set = true, value = true, name = 2^4 } },
  ["4:2"] =  { attribute = "underdouble",   definition = { set = true, value = true, name = 2^5 } },
  ["4:3"] =  { attribute = "undercurl",     definition = { set = true, value = true, name = 2^6 } },
  ["4:4"] =  { attribute = "underdotted",   definition = { set = true, value = true, name = 2^7 } },
  ["4:5"] =  { attribute = "underdashed",   definition = { set = true, value = true, name = 2^8 } },
}

return ansi
