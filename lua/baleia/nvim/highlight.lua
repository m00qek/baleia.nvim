local module = {}

local nvim = {
  buffer = require("baleia.nvim.buffer"),
  api = require("baleia.nvim.api"),
}

---@param logger Logger
---@param namespace integer
---@param buffer integer
---@param marks Mark[]
---@param highlights { [string]: HighlightAttributes }
function module.all(logger, namespace, buffer, marks, highlights)
  local hl = nvim.api.highlights(logger, 0)
  for name, attributes in pairs(highlights) do
    if hl.undefined(name) then
      nvim.buffer.create_highlight(logger, name, attributes)
    end
  end

  for _, mark in ipairs(marks) do
    nvim.buffer.add_highlight(
      logger,
      buffer,
      namespace,
      mark.highlight,
      mark.line - 1,
      mark.firstcolumn - 1,
      mark.lastcolumn
    )
  end
end

return module
