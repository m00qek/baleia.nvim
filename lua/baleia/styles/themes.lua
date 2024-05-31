local M = {}

---@alias Theme { integer: string }

---@type Theme
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

---@type Theme
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
