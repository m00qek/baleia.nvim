local highlights = require('baleia.highlight')
local lines = require('baleia.lines')
local nvim = require('baleia.nvim')

local baleia = {}

local function highlight_all(options, buffer, ns, offset, buffer_lines) 
  local actions = highlights.all(options, offset, buffer_lines)

  for _, definition in ipairs(actions.definitions) do
    nvim.create_highlight(definition.name, definition.attributes)
  end

  for _, highlight in ipairs(actions.highlights) do
    nvim.highlight(buffer, ns, highlight)
  end
end

local function with_default_options(options) 
  local predicate = function(line) return line:sub(1, 1) == ';' end
  return {
    line_starts_at = options.line_starts_at or 3,
    get_lines = options.get_lines or lines.take_while(predicate),
    name = options.name or 'ConjureLogColors'
  }
end

function baleia.setup(options) 
  local opts = with_default_options(options)
  local ns = nvim.create_namespace(opts.name)

  return { 
    once = function(buffer)
      local range = lines.all()(nvim.get_lines, buffer)
      local offset = { column = 0, line = range.first - 1}

      highlight_all(opts, buffer, ns, offset, range.lines)   
    end,
    automatically = function(buffer) 
      nvim.execute_on_change(buffer, ns, function(_, _, firstline, lastline)
        local range = opts.get_lines(nvim.get_lines, buffer, firstline, lastline)
        local offset = { column = 0, line = range.first - 1}

        highlight_all(opts, buffer, ns, offset, range.lines)   
      end)
    end
  }
end

return baleia
