local styles = require("baleia.new_styles")

local M = {}

---@class baleia.LexerItem
---@field text string The processed text content (stripped or raw)
---@field highlights baleia.LexerHighlight[] List of highlights strictly within this line

---@class baleia.LexerHighlight
---@field from integer Start column (0-indexed)
---@field to integer End column (0-indexed, inclusive)
---@field style table The style to apply

local function is_active(style)
  return next(style) ~= nil
end

---Lexes a list of lines.
---Highlights are broken at line boundaries (no multiline marks).
---@param lines string[] The lines to process
---@param strip_ansi_codes boolean? If true, ANSI codes are removed. (Default: true)
---@param start_highlighting_at integer? Column offset applied to ALL lines. (Default: 0)
---@param seed_style table? Initial style state. (Default: {})
---@return baleia.LexerItem[], table
function M.lex(lines, strip_ansi_codes, start_highlighting_at, seed_style)
  local output = {}

  -- State persists across lines.
  -- If Line 1 ends in "Red", Line 2 starts in "Red".
  -- We must clone the seed because we mutate 'state' throughout the process.
  local state = seed_style and styles.clone(seed_style) or {}

  local strip = strip_ansi_codes == nil and true or strip_ansi_codes
  local offset = start_highlighting_at or 0

  for _, line in ipairs(lines) do
    local clean_line = ""
    local line_highlights = {}

    -- The current writing position for this specific line (0-indexed)
    local current_col = 0

    -- "Snapshot" of the state at the start of the current span
    local span_start = current_col
    local span_style = styles.clone(state)

    local cursor = 1
    while cursor <= #line do
      local start_seq, end_seq = string.find(line, styles.PATTERN, cursor)

      if not start_seq then
        -- No more codes, append remaining text
        local text_part = string.sub(line, cursor)
        clean_line = clean_line .. text_part
        current_col = current_col + #text_part
        break
      end

      -- 1. Handle Text before the code
      if start_seq > cursor then
        local text_part = string.sub(line, cursor, start_seq - 1)
        clean_line = clean_line .. text_part
        current_col = current_col + #text_part
      end

      -- 2. Handle the Code (State Change)
      -- If we have advanced since the last start, we must "close" the current mark
      -- before the style changes.
      if current_col > span_start then
        local from = math.max(offset, span_start)
        local to = math.max(offset, current_col) - 1

        if to >= from and is_active(span_style) then
          table.insert(line_highlights, {
            from = from,
            to = to,
            style = span_style,
          })
        end
        span_start = current_col
      end

      -- Update the state
      local code = string.sub(line, start_seq, end_seq)
      -- 'styles.apply' mutates 'state' in place
      styles.apply(code, state)
      
      -- We clone 'state' for the next span so that future mutations don't affect this reference
      span_style = styles.clone(state)

      -- If NOT stripping, the code adds to the text length
      if not strip then
        clean_line = clean_line .. code
        current_col = current_col + #code
        span_start = current_col
      end

      cursor = end_seq + 1
    end

    -- Close final span for this line
    if current_col > span_start then
      local from = math.max(offset, span_start)
      local to = math.max(offset, current_col) - 1

      if to >= from and is_active(span_style) then
        table.insert(line_highlights, {
          from = from,
          to = to,
          style = span_style,
        })
      end
    end

    table.insert(output, {
      text = clean_line,
      highlights = line_highlights,
    })
  end

  return output, state
end

return M
