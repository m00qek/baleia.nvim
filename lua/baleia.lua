local nvim = require('baleia.nvim')
local styles = require('baleia.styles')
local locations = require('baleia.locations')
local lines = require('baleia.lines')

local START_OF_LINE = 3

local baleia = {}

local function highlight(buffer, ns, name, location)
  nvim.create_highlight(name, styles.attributes(location.style))

  if location.start.line == location['end'].line then
    nvim.highlight(buffer, ns, name, {
      firstcolumn = location.start.column,
      lastcolumn = location['end'].column,
      line = location.start.line
    })
  else
    nvim.highlight(buffer, ns, name, {
      firstcolumn = location.start.column,
      line = location.start.line
    })

    for line = location.start.line + 1, location['end'].line - 1 do
      nvim.highlight(buffer, ns, name, {
        firstcolumn = START_OF_LINE,
        line = line
      })
    end

    nvim.highlight(buffer, ns, name, {
      firstcolumn = START_OF_LINE,
      lastcolumn = location['end'].column,
      line = location['end'].line
    })
  end
end


local function highlight_all(options, buffer, ns, offset, buffer_lines) 
  local extracted_locations = locations.extract(buffer_lines, styles.to_style)
  for _, location in pairs(extracted_locations) do
    local name = styles.name(options.name, location.style)
    highlight(buffer, ns, name, locations.with_offset(offset, location))
  end
end

--        vim.api.nvim_command('echom "' .. range.first .. "')
function baleia.setup(options) 
  local ns = nvim.create_namespace(options.name)
  local last_lines = lines.take_while(function(line) return line:sub(1, 1) == ';' end)

  return { 
    once = function(buffer)
      local range = lines.all()(nvim.get_lines, buffer)
      highlight_all(options, buffer, ns, { column = 0, line = range.first - 1}, range.lines)   
    end,
    automatically = function(buffer) 
      nvim.execute_on_change(buffer, ns, 
      function(_, _, firstline, lastline)
        local range = last_lines(nvim.get_lines, buffer, firstline, lastline)
        highlight_all(options, buffer, ns, { column = 0, line = range.first - 1 }, range.lines)   
      end)
    end
  }
end

return baleia
