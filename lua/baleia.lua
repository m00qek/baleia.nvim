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

local function reverse(list)
  local reversed = {}
  for i = #list, 1, -1 do
    reversed[#reversed + 1] = list[i]
  end

  return reversed
end

local function all_lines()
  return function(buffer) 
    return {
      lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, true),
      first = 1
    }
  end
end

local function take_while(predicate)
  return function(buffer, _, lastline)
    local lines = {}
    for line = lastline, 1, -1 do
      local text = vim.api.nvim_buf_get_lines(buffer, line, line + 1, true)[1]
      if not predicate(text) then
        break
      end 
      table.insert(lines, text)
    end
    
    return { lines = reverse(lines), first = lastline - #lines + 1 }
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
  local last_lines = take_while(function(line) return line:sub(1, 1) == ';' end)

  return { 
    once = function(buffer)
      local range = all_lines()(buffer)
      highlight_all(options, buffer, ns, { column = 0, line = range.first }, range.lines)   
    end,
    automatically = function(buffer) 
      nvim.execute_on_change(buffer, ns, 
      function(_, _, firstline, lastline)
        local range = last_lines(buffer, firstline + 1, lastline + 1)
        highlight_all(options, buffer, ns, { column = 0, line = range.first }, range.lines)   
      end)
    end
  }
end

return baleia
