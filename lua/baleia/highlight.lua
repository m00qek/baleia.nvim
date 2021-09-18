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

local function apply_offset(offset, strip_ansi_codes, lines, locs)
  local offseted_lines = { }
  local new_locs

  if strip_ansi_codes then
     new_locs = locations.strip_ansi_codes(locs)

     for _, line in ipairs(lines) do
        local stripped_line = line:gsub(require("baleia.ansi").PATTERN, '')
        table.insert(offseted_lines, stripped_line)
     end
  else
     new_locs = locations.ignore_ansi_codes(locs)
     offseted_lines = lines
  end

  return offseted_lines, locations.with_offset(offset, new_locs)
end

function highlight.all(options, offset, lines)
  local definitions = {}
  local all_highlights = {}

  local offseted_lines, locs = apply_offset(offset,
                                            options.strip_ansi_codes,
                                            lines,
                                            locations.extract(lines))

  for index = #locs, 1, -1 do
    local location = locs[index]
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
    lines = offseted_lines
  }
end

return highlight
