local styles = require('baleia.styles')

local locations = {}

function locations.extract(lines, to_style) 
  local extracted = {}

  for line, text in pairs(lines) do
    local position = 1

    for ansi_sequence in  text:gmatch('\x1b[[:;0-9]*m') do
      local column = text:find('\x1b[[:;0-9]*m', position) 

      table.insert(extracted, {
        style = to_style(ansi_sequence) ,
        from = { column = column, line = line }
      })

      position = column + 1
    end
  end

  for index, location in ipairs(extracted) do 
    local previous_location = extracted[index - 1]
    if previous_location then 
      location.style = styles.merge(previous_location.style, location.style)
    end

    local next_location = extracted[index + 1]
    if next_location and next_location.from.column > 1  then 
      location.to = next_location.from
    elseif next_location then 
      location.to = { line = location.from.line - 1 }
    else
      location.to = { line = location.from.line }
    end
  end

  return extracted
end

function locations.with_offset(offset, location)
  local endcolumn = location.to.column
  if endcolumn then
    endcolumn = endcolumn + offset.column
  end

  return {
    style = location.style,
    from = { 
      line = location.from.line + offset.line,
      column = location.from.column + offset.column,
    },
    to = { 
      line = location.to.line + offset.line,
      column = endcolumn
    }
  }
end

return locations
