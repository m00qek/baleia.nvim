local lines = {}

local function reverse(list)
  local reversed = {}
  for i = #list, 1, -1 do
    reversed[#reversed + 1] = list[i]
  end

  return reversed
end

function lines.all()
  return function(line_getter, buffer) 
    return {
      lines = line_getter(buffer, 1),
      first = 1
    }
  end
end

function lines.moving_window(number)
  return function(line_getter, buffer, firstline) 
    local line = firstline - number
    if line < 1 then
      line = 1
    end

    return {
      lines = line_getter(buffer, line),
      first = line
    }
  end
end

function lines.take_while(predicate)
  return function(line_getter, buffer, _, lastline)
    local buffer_lines = {}

    for line = lastline, 1, -1 do
      local text = line_getter(buffer, line, line + 1)[1]
      if not predicate(text) then
        break
      end 
      table.insert(buffer_lines, text)
    end
    
    return {
      lines = reverse(buffer_lines),
      first = lastline - #buffer_lines + 1 
    }
  end
end

return lines
