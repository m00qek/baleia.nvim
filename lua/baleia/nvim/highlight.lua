local module = {}

local nvim = {
   buffer = require("baleia/nvim/buffer"),
   api = require("baleia/nvim/api"),
}

function module.create(logger, name, attributes)
   local command = name

   if attributes.modes then
      command = command .. ' cterm=' .. table.concat(attributes.modes, ',')
      command = command .. ' gui=' .. table.concat(attributes.modes, ',')
   end

   attributes.modes = nil
   for attr, value in pairs(attributes) do
      if value then
         command = command .. ' ' .. attr .. '=' .. value
      end
   end

   if command ~= name then
      return nvim.api.execute(logger, 'highlight ' .. command)
   end
end

function module.all(logger, buffer, ns, definitions, highlights)
   for name, attributes in pairs(definitions) do
      module.create(logger, name, attributes)
   end

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
end

return module
