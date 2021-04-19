local END_OF_LINE = -1

local module = {}

function module.create(name, attributes)
  local command = 'highlight ' .. name

  if attributes.cterm then
      command = command .. ' cterm=' .. table.concat(attributes.cterm, ',')
  end

  attributes.cterm = nil
  for attr, value in pairs(attributes) do
    if value then
      command = command .. ' ' .. attr .. '=' .. value
    end
  end

  return vim.api.nvim_command(command)
end

function module.one(buffer, ns, highlight)
  local lastcolumn = END_OF_LINE
  if highlight.lastcolumn then
    lastcolumn = highlight.lastcolumn - 1
  end

  return vim.api.nvim_buf_add_highlight(buffer, ns, highlight.name,
    highlight.line - 1, highlight.firstcolumn - 1, lastcolumn)
end

function module.all(buffer, ns, definitions, highlights)
  for _, definition in ipairs(definitions) do
    module.create(definition.name, definition.attributes)
  end

  for _, highlight in ipairs(highlights) do
    module.one(buffer, ns, highlight)
  end
end

return module

