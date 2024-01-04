---@meta _
--# selene: allow(unused_variable)
error("Cannot require a meta file")

---@class UserOptions
---@field strip_ansi_codes? boolean
---@field line_starts_at? integer
---@field colors? Theme
---@field async? boolean
---@field name? string
---@field log? string

---@class Baleia
local baleia = {}

--- Logger for Baleia
---@type Logger
baleia.logger = nil

--- Parses the contents of {buffer} and colorizes them respecting any ANSI
--- color codes present in the text.
---
-- Parameters: ~
--   • {buffer}  Buffer handle
--- @param buffer buffer
function baleia.once(buffer) end

--- Every time a new line is added to {buffer}, parses the new contents and
--- colorizes them respecting any ANSI color codes present in the text.
---
-- Parameters: ~
--   • {buffer}  Buffer handle
--- @param buffer buffer
function baleia.automatically(buffer) end

-- Sets (replaces) a line-range in the buffer, parses ANSI color codes and
-- colorizes the resulting text accordingly.
--
-- Indexing is zero-based, end-exclusive. Negative indices are interpreted as
-- length+1+index: -1 refers to the index past the end. So to change or
-- delete the last element use start=-2 and end=-1.
--
-- To insert lines at a given index, set `start` and `end` to the same index.
-- To delete a range of lines, set `replacement` to an empty array.
--
-- Out-of-bounds indices are clamped to the nearest valid value, unless
-- `strict_indexing` is set.
--
-- Attributes: ~
--     not allowed when |textlock| is active
--
-- Parameters: ~
--   • {buffer}           Buffer handle, or 0 for current buffer
--   • {start}            First line index
--   • {end}              Last line index, exclusive
--   • {strict_indexing}  Whether out-of-bounds should be an error.
--   • {replacement}      Array of lines to use as replacement
--
-- See also: ~
--   • |nvim_buf_set_text()|
--- @param buffer buffer
--- @param start number
--- @param end_ number
--- @param strict_indexing boolean
--- @param replacement string[]
--- @see baleia.buf_set_text
function baleia.buf_set_lines(buffer, start, end_, strict_indexing, replacement) end

-- Sets (replaces) a range in the buffer, parses ANSI color codes and colorizes
-- the resulting lines accordingly.
--
-- This is recommended over |nvim_buf_set_lines()| when only modifying parts
-- of a line, as extmarks will be preserved on non-modified parts of the
-- touched lines.
--
-- Indexing is zero-based. Row indices are end-inclusive, and column indices
-- are end-exclusive.
--
-- To insert text at a given `(row, column)` location, use `start_row =
-- end_row = row` and `start_col = end_col = col`. To delete the text in a
-- range, use `replacement = {}`.
--
-- Prefer |buf_set_lines()| if you are only adding or deleting entire
-- lines.
--
-- Attributes: ~
--     not allowed when |textlock| is active
--
-- Parameters: ~
--   • {buffer}       Buffer handle, or 0 for current buffer
--   • {start_row}    First line index
--   • {start_col}    Starting column (byte offset) on first line
--   • {end_row}      Last line index, inclusive
--   • {end_col}      Ending column (byte offset) on last line, exclusive
--   • {replacement}  Array of lines to use as replacement
--
-- See also: ~
--   • |nvim_buf_set_lines()|
--- @param buffer buffer
--- @param start_row number
--- @param start_col number
--- @param end_row number
--- @param end_col number
--- @param replacement string[]
--- @see baleia.buf_set_lines
function baleia.buf_set_text(buffer, start_row, start_col, end_row, end_col, replacement) end

return baleia
