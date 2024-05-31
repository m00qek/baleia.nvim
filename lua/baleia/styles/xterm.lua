-- This is basically a translation to Lua from the C codebase of TMUX
-- https://github.com/tmux/tmux/blob/dae2868d1227b95fd076fb4a5efa6256c7245943/colour.c

local M = {}

local function distance(color1, color2)
  return (color1.red - color2.red) ^ 2 + (color1.green - color2.green) ^ 2 + (color1.blue - color2.blue) ^ 2
end

local function to_6cube(color)
  if color < 48 then
    return 0
  end

  if color < 114 then
    return 1
  end

  return math.floor((color - 35) / 40)
end

local function closest_color(original_color)
  local red = to_6cube(original_color.red)
  local green = to_6cube(original_color.green)
  local blue = to_6cube(original_color.blue)

  local code = 16 + (36 * red) + (6 * green) + blue

  return code, { red = red, green = green, blue = blue }
end

local function closest_grey(original_color)
  local average = math.floor((original_color.red + original_color.green + original_color.blue) / 3)

  local code = math.floor((average - 3) / 10)
  if average > 238 then
    code = 23
  end

  local grey = 8 + 10 * code
  return code + 232, { red = grey, green = grey, blue = grey }
end

local within_levels = { [0] = 0x00, [1] = 0x5f, [2] = 0x87, [3] = 0xaf, [4] = 0xd7, [5] = 0xff }

-- Completes {theme} with current colorscheme
--
-- Parameters: ~
--   • {code}  ANSI color code (between 0 and 255)
---@param code integer
---@return string
function M.to_truecolor(code)
  return "#" .. M.colors[code]
end

-- Convert an RGB triplet to the xterm 256 colour palette.
--
-- xterm provides a 6x6x6 colour cube (16 - 231) and 24 greys (232 - 255). We
-- map our RGB colour to the closest in the cube, also work out the closest
-- grey, and use the nearest of the two.
--
-- Note that the xterm has much lower resolution for darker colours (they are
-- not evenly spread out), so our 6 levels are not evenly spread: 0x0, 0x5f
-- (95), 0x87 (135), 0xaf (175), 0xd7 (215) and 0xff (255). Greys are more
-- evenly spread (8, 18, 28 ... 238).
--
-- Parameters: ~
--   • {red}    Red color component (between 0 and 255)
--   • {green}  Red color component (between 0 and 255)
--   • {blue}   Red color component (between 0 and 255)
---@param red integer
---@param green integer
---@param blue integer
---@return integer
function M.from_rgb(red, green, blue)
  local original = { red = red, green = green, blue = blue }

  -- Map RGB to 6x6x6 cube.
  local color_code, color = closest_color(original)

  local leveled = {
    red = within_levels[color.red],
    green = within_levels[color.green],
    blue = within_levels[color.blue],
  }

  -- If we have hit the colour exactly, return early.
  if leveled.red == red and leveled.green == green and leveled.blue == blue then
    return color_code
  end

  -- Work out the closest grey (average of RGB).
  local grey_code, grey = closest_grey(original)

  -- Is grey or 6x6x6 colour closest?
  if distance(grey, original) < distance(leveled, original) then
    return grey_code
  end

  return color_code
end

---@type { [integer]: string }
M.colors = {
  [000] = "000000",
  [001] = "800000",
  [002] = "008000",
  [003] = "808000",
  [004] = "000080",
  [005] = "800080",
  [006] = "008080",
  [007] = "c0c0c0",
  [008] = "808080",
  [009] = "ff0000",
  [010] = "00ff00",
  [011] = "ffff00",
  [012] = "0000ff",
  [013] = "ff00ff",
  [014] = "00ffff",
  [015] = "ffffff",
  [016] = "000000",
  [017] = "00005f",
  [018] = "000087",
  [019] = "0000af",
  [020] = "0000d7",
  [021] = "0000ff",
  [022] = "005f00",
  [023] = "005f5f",
  [024] = "005f87",
  [025] = "005faf",
  [026] = "005fd7",
  [027] = "005fff",
  [028] = "008700",
  [029] = "00875f",
  [030] = "008787",
  [031] = "0087af",
  [032] = "0087d7",
  [033] = "0087ff",
  [034] = "00af00",
  [035] = "00af5f",
  [036] = "00af87",
  [037] = "00afaf",
  [038] = "00afd7",
  [039] = "00afff",
  [040] = "00d700",
  [041] = "00d75f",
  [042] = "00d787",
  [043] = "00d7af",
  [044] = "00d7d7",
  [045] = "00d7ff",
  [046] = "00ff00",
  [047] = "00ff5f",
  [048] = "00ff87",
  [049] = "00ffaf",
  [050] = "00ffd7",
  [051] = "00ffff",
  [052] = "5f0000",
  [053] = "5f005f",
  [054] = "5f0087",
  [055] = "5f00af",
  [056] = "5f00d7",
  [057] = "5f00ff",
  [058] = "5f5f00",
  [059] = "5f5f5f",
  [060] = "5f5f87",
  [061] = "5f5faf",
  [062] = "5f5fd7",
  [063] = "5f5fff",
  [064] = "5f8700",
  [065] = "5f875f",
  [066] = "5f8787",
  [067] = "5f87af",
  [068] = "5f87d7",
  [069] = "5f87ff",
  [070] = "5faf00",
  [071] = "5faf5f",
  [072] = "5faf87",
  [073] = "5fafaf",
  [074] = "5fafd7",
  [075] = "5fafff",
  [076] = "5fd700",
  [077] = "5fd75f",
  [078] = "5fd787",
  [079] = "5fd7af",
  [080] = "5fd7d7",
  [081] = "5fd7ff",
  [082] = "5fff00",
  [083] = "5fff5f",
  [084] = "5fff87",
  [085] = "5fffaf",
  [086] = "5fffd7",
  [087] = "5fffff",
  [088] = "870000",
  [089] = "87005f",
  [090] = "870087",
  [091] = "8700af",
  [092] = "8700d7",
  [093] = "8700ff",
  [094] = "875f00",
  [095] = "875f5f",
  [096] = "875f87",
  [097] = "875faf",
  [098] = "875fd7",
  [099] = "875fff",
  [100] = "878700",
  [101] = "87875f",
  [102] = "878787",
  [103] = "8787af",
  [104] = "8787d7",
  [105] = "8787ff",
  [106] = "87af00",
  [107] = "87af5f",
  [108] = "87af87",
  [109] = "87afaf",
  [110] = "87afd7",
  [111] = "87afff",
  [112] = "87d700",
  [113] = "87d75f",
  [114] = "87d787",
  [115] = "87d7af",
  [116] = "87d7d7",
  [117] = "87d7ff",
  [118] = "87ff00",
  [119] = "87ff5f",
  [120] = "87ff87",
  [121] = "87ffaf",
  [122] = "87ffd7",
  [123] = "87ffff",
  [124] = "af0000",
  [125] = "af005f",
  [126] = "af0087",
  [127] = "af00af",
  [128] = "af00d7",
  [129] = "af00ff",
  [130] = "af5f00",
  [131] = "af5f5f",
  [132] = "af5f87",
  [133] = "af5faf",
  [134] = "af5fd7",
  [135] = "af5fff",
  [136] = "af8700",
  [137] = "af875f",
  [138] = "af8787",
  [139] = "af87af",
  [140] = "af87d7",
  [141] = "af87ff",
  [142] = "afaf00",
  [143] = "afaf5f",
  [144] = "afaf87",
  [145] = "afafaf",
  [146] = "afafd7",
  [147] = "afafff",
  [148] = "afd700",
  [149] = "afd75f",
  [150] = "afd787",
  [151] = "afd7af",
  [152] = "afd7d7",
  [153] = "afd7ff",
  [154] = "afff00",
  [155] = "afff5f",
  [156] = "afff87",
  [157] = "afffaf",
  [158] = "afffd7",
  [159] = "afffff",
  [160] = "d70000",
  [161] = "d7005f",
  [162] = "d70087",
  [163] = "d700af",
  [164] = "d700d7",
  [165] = "d700ff",
  [166] = "d75f00",
  [167] = "d75f5f",
  [168] = "d75f87",
  [169] = "d75faf",
  [170] = "d75fd7",
  [171] = "d75fff",
  [172] = "d78700",
  [173] = "d7875f",
  [174] = "d78787",
  [175] = "d787af",
  [176] = "d787d7",
  [177] = "d787ff",
  [178] = "d7af00",
  [179] = "d7af5f",
  [180] = "d7af87",
  [181] = "d7afaf",
  [182] = "d7afd7",
  [183] = "d7afff",
  [184] = "d7d700",
  [185] = "d7d75f",
  [186] = "d7d787",
  [187] = "d7d7af",
  [188] = "d7d7d7",
  [189] = "d7d7ff",
  [190] = "d7ff00",
  [191] = "d7ff5f",
  [192] = "d7ff87",
  [193] = "d7ffaf",
  [194] = "d7ffd7",
  [195] = "d7ffff",
  [196] = "ff0000",
  [197] = "ff005f",
  [198] = "ff0087",
  [199] = "ff00af",
  [200] = "ff00d7",
  [201] = "ff00ff",
  [202] = "ff5f00",
  [203] = "ff5f5f",
  [204] = "ff5f87",
  [205] = "ff5faf",
  [206] = "ff5fd7",
  [207] = "ff5fff",
  [208] = "ff8700",
  [209] = "ff875f",
  [210] = "ff8787",
  [211] = "ff87af",
  [212] = "ff87d7",
  [213] = "ff87ff",
  [214] = "ffaf00",
  [215] = "ffaf5f",
  [216] = "ffaf87",
  [217] = "ffafaf",
  [218] = "ffafd7",
  [219] = "ffafff",
  [220] = "ffd700",
  [221] = "ffd75f",
  [222] = "ffd787",
  [223] = "ffd7af",
  [224] = "ffd7d7",
  [225] = "ffd7ff",
  [226] = "ffff00",
  [227] = "ffff5f",
  [228] = "ffff87",
  [229] = "ffffaf",
  [230] = "ffffd7",
  [231] = "ffffff",
  [232] = "080808",
  [233] = "121212",
  [234] = "1c1c1c",
  [235] = "262626",
  [236] = "303030",
  [237] = "3a3a3a",
  [238] = "444444",
  [239] = "4e4e4e",
  [240] = "585858",
  [241] = "626262",
  [242] = "6c6c6c",
  [243] = "767676",
  [244] = "808080",
  [245] = "8a8a8a",
  [246] = "949494",
  [247] = "9e9e9e",
  [248] = "a8a8a8",
  [249] = "b2b2b2",
  [250] = "bcbcbc",
  [251] = "c6c6c6",
  [252] = "d0d0d0",
  [253] = "dadada",
  [254] = "e4e4e4",
  [255] = "eeeeee",
}

return M
