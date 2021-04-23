local styles = require("baleia.styles")
local ansi = require("baleia.ansi")

local locations = {}

local function linelocs(line, text)
   local extracted = { }

   local position = 1
   for ansi_sequence in text:gmatch(ansi.PATTERN) do
      local column = text:find(ansi.PATTERN, position)
      table.insert(extracted, {
         style = styles.to_style(ansi_sequence),
         from  = { line = line, column = column }
      })
      position = column + 1
   end

   return extracted
end

function locations.extract(lines)
   local lastcolumn = nil
   local lastline = #lines

   local extracted = { }

   for index = #lines, 1, -1 do
      local locs = linelocs(index, lines[index])

      for loc = #locs, 1, -1 do
         local location = locs[loc]

         location.to = { line = lastline, column = lastcolumn }
         table.insert(extracted, location)

         lastline = index
         lastcolumn = location.from.column - 1
         if lastcolumn < 1 then
            lastline = lastline - 1
            lastcolumn = nil
         end

      end
   end

   return extracted
end

function locations.with_offset(offset, location)
  return {
    style = location.style,
    from = {
      line = location.from.line + offset.line,
      column = location.from.column + location.style.offset + offset.column,
    },
    to = {
      line = location.to.line + offset.line,
      column = location.to.column and location.to.column + offset.column
    }
  }
end

return locations
