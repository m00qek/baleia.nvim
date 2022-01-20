local nvim = {
  highlight = require("baleia.nvim.highlight"),
  buffer = require("baleia.nvim.buffer"),
  window = require("baleia.nvim.window"),
  colors = require("baleia.nvim.colors"),
}

local nvim_api = require("baleia.nvim.api")

for name, fn in pairs(nvim_api) do
  nvim[name] = fn
end

return nvim
