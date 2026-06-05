local ansi = require("baleia.ansi")

local M = {}

-- A style with every common attribute set. After a true reset sequence is
-- applied, all keys are cleared and next(style) == nil.
local SENTINEL = { ctermfg = 1, ctermbg = 1, bold = true, italic = true, underline = true }

local function is_reset_sequence(seq)
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

---Scans backward from line w0 (0-indexed) to find the nearest reset boundary.
---Returns the 0-indexed line number of that boundary, or 0 if none is found.
---@param buffer integer
---@param w0 integer First visible line, 0-indexed
---@return integer
function M.find_split(buffer, w0)
  for line_nr = w0, 0, -1 do
    local lines = vim.api.nvim_buf_get_lines(buffer, line_nr, line_nr + 1, false)
    if lines[1] and M.is_reset_boundary(lines[1]) then
      return line_nr
    end
  end
  return 0
end

return M
