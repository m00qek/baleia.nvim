local ansi = require("baleia.ansi")

local colors = {}

function colors.theme()
  local nvim_colors = {}

  for index, color in pairs(ansi.COLORS) do
    nvim_colors[color] = vim.g["terminal_color_" .. index - 1] or color
  end

  return nvim_colors
end

return colors
