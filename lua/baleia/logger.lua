local api = require("baleia.logger.api")

local M = {}

local function do_nothing() end

local function logfn(level, buffer, current_priority, hlgroup, hlnamespace)
  if api.LEVELS[level].priority > current_priority then
    return do_nothing
  end

  return function(message, data)
    vim.schedule(function()
      api.log(buffer, hlgroup, hlnamespace, level, message, data)
    end)
  end
end

-- Creates a logger that does not log anything.
--
--- @return baleia.Logger
function M.null()
  return api.NULL_LOGGER
end

-- Creates a logger that logs only levels equal or more severe then {level}.
--
-- Parameters: ~
--   • {hlgroup}      Highlight group name
--   • {hlnamespace}  Highlight group namespace
--   • {level}        Log level
---@param hlgroup string
---@param hlnamespace integer
---@param level string
---@return baleia.Logger
function M.new(hlgroup, hlnamespace, level)
  local buffer = api.create(hlgroup)
  local current_priority = api.LEVELS[level].priority

  return {
    show = function()
      api.show(buffer)
    end,

    error = logfn("ERROR", buffer, current_priority, hlgroup, hlnamespace),
    warn = logfn("WARN", buffer, current_priority, hlgroup, hlnamespace),
    info = logfn("INFO", buffer, current_priority, hlgroup, hlnamespace),
    debug = logfn("DEBUG", buffer, current_priority, hlgroup, hlnamespace),
  }
end

return M
