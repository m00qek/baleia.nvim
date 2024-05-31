---@class baleia.styles.attributes.modes.Value
---@field tag integer
---@field enabled boolean

---@class baleia.styles.attributes.Mode
---@field set boolean
---@field value baleia.styles.attributes.modes.Value

local M = {}

-- Applies a mode attribute to a highlight
--
-- Parameters: ~
--   • {tag}  Unique identifier used to generate highlight group names
---@param tag integer
---@return baleia.styles.attributes.Mode
function M.turn_on(tag)
  return {
    set = true,
    value = { enabled = true, tag = tag },
  }
end

-- Clears a mode attribute in a highlight
--
-- Parameters: ~
--   • {tag}  Unique identifier used to generate highlight group names
---@param tag integer
---@return baleia.styles.attributes.Mode
function M.turn_off(tag)
  return {
    set = true,
    value = { enabled = false, tag = tag },
  }
end

-- Ignores a mode attribute in a highlight
--
-- Parameters: ~
--   • {tag}  Unique identifier used to generate highlight group names
---@param tag integer
---@return baleia.styles.attributes.Mode
function M.ignore(tag)
  return {
    set = false,
    value = { enabled = false, tag = tag },
  }
end

return M
