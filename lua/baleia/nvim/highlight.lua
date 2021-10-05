local END_OF_LINE = -1

local module = {}

function module.create(name, attributes)
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
      return vim.cmd('highlight ' .. command)
   end
end

function module.one(buffer, ns, highlight)
   return vim.api.nvim_buf_add_highlight(
      buffer,
      ns,
      highlight.name,
      highlight.line - 1,
      highlight.firstcolumn - 1,
      highlight.lastcolumn or END_OF_LINE)
end

function module.all(buffer, ns, definitions, highlights)
   for name, attributes in pairs(definitions) do
      module.create(name, attributes)
   end

   for _, highlight in ipairs(highlights) do
      module.one(buffer, ns, highlight)
   end
end

return module
