local module = {}

local nvim = {
   buffer = require("baleia/nvim/buffer"),
   api = require("baleia/nvim/api"),
}

function module.all(logger, buffer, ns, definitions, highlights)
   vim.schedule(function()
      for name, attributes in pairs(definitions) do
         nvim.buffer.create_highlight(logger, name, attributes)
      end
   end)

   vim.schedule(function()
      for _, highlight in ipairs(highlights) do
         nvim.buffer.add_highlight(
            logger,
            buffer,
            ns,
            highlight.name,
            highlight.line - 1,
            highlight.firstcolumn - 1,
            highlight.lastcolumn)
      end
   end)
end

return module
