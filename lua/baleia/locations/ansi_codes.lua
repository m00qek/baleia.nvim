local styles = require("baleia.styles")

local M = {}

local function rpairs(table)
  return function(t, i)
    i = i - 1
    if i ~= 0 then
      return i, t[i]
    end
  end, table, #table + 1
end

local function iterator(opts)
  if opts.backwards then
    return ipairs
  end

  return rpairs
end

local function iterate(lines)
  local result = {}

  local lastline = #lines
  local lastcolumn = nil

  for line_number, text in rpairs(lines) do
    local codes = {}
    local position = 1
    for ansi_sequence in string.gmatch(text, styles.ANSI_CODES_PATTERN) do
      local from = {
        line = line_number,
        column = string.find(text, styles.ANSI_CODES_PATTERN, position) or 0,
      }

      table.insert(codes, { ansi_sequence, from })
      position = from.column + 1
    end

    for _, value in rpairs(codes) do
      local ansi_sequence, from = value[1], value[2]
      local to = {
        line = lastline,
        column = lastcolumn,
      }

      table.insert(result, { ansi_sequence, from, to })

      lastline = line_number
      lastcolumn = from.column - 1
      if lastcolumn < 1 then
        lastline = lastline - 1
        lastcolumn = nil
      end
    end
  end

  return result
end

---@param locations Location[]
---@return Location[]
function M.ignore(locations)
  for _, location in ipairs(locations) do
    location.from.column = location.from.column + location.style.offset
  end

  return locations
end

---@param locations Location[]
---@return Location[]
function M.strip(locations)
  local line_number = locations[1].to.line
  local offset = 0

  for _, location in ipairs(locations) do
    if line_number ~= location.from.line then
      line_number = location.from.line
      offset = 0
    end

    location.from.column = location.from.column - offset
    offset = offset + location.style.offset

    if not location.to.column or line_number ~= location.to.line then
      line_number = location.to.line
      offset = 0
    else
      location.to.column = location.to.column - offset
    end
  end

  return locations
end

---@param lines string[]
---@param fn fun(ansi_sequence: string, from: StrictPosition, to: LoosePosition)
---@param options? { backwards?: boolean }
function M.foreach(lines, fn, options)
  local opts = options or {}

  for _, code in iterator(opts)(iterate(lines)) do
    fn(unpack(code))
  end
end

---@generic T
---@param lines string[]
---@param fn fun(ansi_sequence: string, from: StrictPosition, to: LoosePosition) : T
---@param options? { backwards?: boolean }
---@return T[]
function M.map(lines, fn, options)
  local opts = options or {}
  local result = {}

  for _, code in iterator(opts)(iterate(lines)) do
    table.insert(result, fn(unpack(code)))
  end

  return result
end

return M
