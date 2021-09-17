local locations = require("baleia.locations")
local styles = require("baleia.styles")

local highlight = {}

local function single_line(name, location)
  return {
    firstcolumn = location.from.column,
    lastcolumn = location.to.column,
    line = location.from.line,
    name = name
  }
end

local function multi_line(line_starts_at, name, location)
  local highlights = {}

  table.insert(highlights, {
    firstcolumn = location.from.column,
    line = location.from.line,
    name = name
  })

  for line = location.from.line + 1, location.to.line - 1 do
    table.insert(highlights, {
      firstcolumn = line_starts_at,
      line = line,
      name = name
    })
  end

  if not location.to.column or line_starts_at < location.to.column then
    table.insert(highlights, {
      firstcolumn = line_starts_at,
      lastcolumn = location.to.column,
      line = location.to.line,
      name = name
    })
  end

  return highlights
end

function highlight.all(options, offset, lines)
  local locs = locations.extract(lines)

  local definitions = {}
  local all_highlights = {}

  local new_lines = { }
  if options.strip_ansi_codes then
     locs = locations.strip(locs)

     for _, line in ipairs(lines) do
        local a = line:gsub(require("baleia.ansi").PATTERN, '')
        table.insert(new_lines, a)
     end
  else
     locs = locations.ignore(locs)
     new_lines = lines
  end

  for index = #locs, 1, -1 do
    local location = locations.with_offset(offset, locs[index])
    local name = styles.name(options.name, location.style)

    if location.from.line == location.to.line then
      table.insert(all_highlights, single_line(name, location))
    else
      local highlights = multi_line(options.line_starts_at, name, location)
      for _, h in ipairs(highlights) do
        table.insert(all_highlights, h)
      end
    end

    definitions[name] = styles.attributes(location.style, options.colors)
  end

  return {
    definitions = definitions,
    highlights = all_highlights,
    lines = new_lines
  }
end

return highlight
