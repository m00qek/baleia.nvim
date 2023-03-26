local colors = require("baleia.nvim.colors")
local ansi = require("baleia.colors.ansi")

local options = {}

function options.with_default(opts)
  opts = opts or { }

  local final_opts = {
    strip_ansi_codes = true,
    line_starts_at = 1,
    colors = colors.theme(ansi.NR_8),
    name = "BaleiaColors",
    log = false,
  }

  for key, _ in pairs(final_opts) do
    local user_value = opts[key]
    if user_value ~= nil then
      final_opts[key] = user_value
    end
  end

  final_opts.loglevel = final_opts.log == true and 'ERROR' or opts.log

  return final_opts
end

return options
