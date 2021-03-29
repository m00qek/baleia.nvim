local nvim = require('baleia.nvim')
local styles = require('baleia.styles')
local locations = require('baleia.locations')

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

local function highlight_all(options, buffer, ns, offset, lines) 
  local extracted_locations = locations.extract(lines, styles.to_style)
  for _, location in pairs(extracted_locations) do
    local name = styles.name(options.name, location.style)
    highlight(buffer, ns, name, locations.with_offset(offset, location))
  end
end

function baleia.setup(options) 
  local ns = nvim.create_namespace(options.name)

  return { 
    once = function(buffer)
      local lines = nvim.get_lines(buffer, 1)
      highlight_all(options, buffer, ns, { column = 0, line = 0 }, lines)   
    end,
    automatically = function(buffer) 
      nvim.execute_on_change(buffer, ns, 
      function()
        local lines = nvim.get_lines(buffer, 1)
        highlight_all(options, buffer, ns, { column = 0, line = 0 }, lines)   
      end)
    end
  }
end

return baleia
