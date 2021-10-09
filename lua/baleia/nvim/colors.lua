local colors = {}

function colors.theme(default_colors)
  local theme_colors = {}

  for index = 0, 255 do
    local color = vim.g["terminal_color_" .. index]
    theme_colors[index] = color or default_colors[index]
  end

  return theme_colors
end

return colors
