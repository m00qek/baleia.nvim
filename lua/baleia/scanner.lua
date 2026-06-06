local ansi = require("baleia.ansi")

local M = {}

-- A style with every possible attribute set. After a true reset sequence is
-- applied, all keys are cleared and next(style) == nil. A partial unset
-- (e.g. \x1b[22m, \x1b[39;49m) cannot clear all fields, so next(style)
-- remains non-nil and the line is not treated as a reset boundary.
local SENTINEL = {
  ctermfg = 1, ctermbg = 1, ctermsp = 1,
  foreground = "#000000", background = "#000000", special = "#000000",
  bold = true, italic = true, underline = true,
  strikethrough = true, reverse = true,
  undercurl = true, underdouble = true, underdotted = true, underdashed = true,
}

local function is_reset_sequence(seq)
  -- A full reset is \x1b[m or \x1b[0...0m. Any non-zero digit means at least
  -- one attribute is being set, so skip the expensive clone+apply path.
  if seq:find("[1-9]") then
    return false
  end
  local style = ansi.clone(SENTINEL)
  ansi.apply(seq, style)
  return next(style) == nil
end

---Returns true if the last ANSI escape sequence on the line is a full reset
---(\x1b[m or \x1b[0m). Handles both the digit-free form and the explicit 0 form.
---This is a pure function with no Neovim API calls.
---@param line string
---@return boolean
function M.is_reset_boundary(line)
  local last_s, last_e
  local pos = 1
  while true do
    local s, e = string.find(line, ansi.PATTERN, pos)
    if not s then
      break
    end
    last_s, last_e = s, e
    pos = e + 1
  end
  if not last_s then
    return false
  end
  return is_reset_sequence(string.sub(line, last_s, last_e))
end

local SCAN_CHUNK = 200

---Scans backward from line w0 (0-indexed) to find the nearest reset boundary.
---Returns the 0-indexed line number of that boundary, or 0 if none is found.
---Reads lines in chunks to avoid one API call per line.
---@param buffer integer
---@param w0 integer First visible line, 0-indexed
---@return integer
function M.find_split(buffer, w0)
  local scan_end = w0 + 1 -- nvim_buf_get_lines end is exclusive

  while scan_end > 0 do
    local scan_start = math.max(0, scan_end - SCAN_CHUNK)
    local lines = vim.api.nvim_buf_get_lines(buffer, scan_start, scan_end, false)

    for i = #lines, 1, -1 do
      if M.is_reset_boundary(lines[i]) then
        return scan_start + i - 1
      end
    end

    scan_end = scan_start
  end

  return 0
end

return M
