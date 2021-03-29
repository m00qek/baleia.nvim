local locations = {}

function locations.extract(lines, to_style) 
  local extracted = {}

  for line, text in pairs(lines) do
    local position = 1

    for ansi_sequence in  text:gmatch('\x1b[[:;0-9]*m') do
      local column = text:find('\x1b[[:;0-9]*m', position) 

      table.insert(extracted, {
        start = { column = column, line = line},
        style = to_style(ansi_sequence) 
      })

      position = column + 1
    end
  end

  for index, location in ipairs(extracted) do 
    local next_location = extracted[index + 1]

    if next_location and next_location.start.column > 1  then 
      location['end'] = next_location.start
    elseif next_location then 
      location['end'] = { line = location.start.line - 1 }
    else
      location['end'] = { line = location.start.line }
    end
  end

  return extracted
end

function locations.with_offset(offset, location)
  local endcolumn = location['end'].column
  if endcolumn then
    endcolumn = endcolumn + offset.column
  end

  return {
    style = location.style,
    start = { 
      line = location.start.line + offset.line,
      column = location.start.column + offset.column,
    },
    ['end'] = { 
      line = location['end'].line + offset.line,
      column = endcolumn
    }
  }
end

return locations
