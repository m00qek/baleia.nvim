local lines = {}

local function reverse(list)
  local reversed = {}
  for i = #list, 1, -1 do
    reversed[#reversed + 1] = list[i]
  end

  return reversed
end

function lines.list(firstline, list)
   return {
      lines = list,
      first = firstline
   }
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
  return function(line_getter, buffer, _, lastline)
    local line = lastline - number + 1
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
    local started = false
    local firstline = lastline

    for line = lastline, 1, -1 do
      local text = line_getter(buffer, line, line + 1)[1]
      local valid = predicate(text)

      if started and not valid then
        break
      end

      if valid then
        table.insert(buffer_lines, text)
      end

      firstline = line
      started = valid
    end

    return {
      lines = reverse(buffer_lines),
      first = firstline
    }
  end
end

return lines
