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
      column = location.from.column + offset.column,
      --column = location.from.column + location.style.offset + offset.column,
    },
    to = {
      line = location.to.line + offset.line,
      column = location.to.column and location.to.column + offset.column
    }
  }
end

function locations.ignore(locs)
   for _, loc in ipairs(locs) do
      loc.from.column = loc.from.column + loc.style.offset
   end

   return locs
end

function locations.strip(locs)
   local line = locs[1].to.line
   local offset = 0

   for index = #locs, 1, -1 do
      local loc = locs[index]

      if line ~= loc.from.line then
        line = loc.from.line
        offset = 0
      end

      loc.from.column = loc.from.column - offset
      offset = offset + loc.style.offset

      if not loc.to.column then
         line = loc.to.line
         offset = 0
      else
         if line ~= loc.to.line then
            line = loc.to.line
            offset = 0
         else
            loc.to.column = loc.to.column - offset
         end
      end
   end

  return locs
end

return locations
