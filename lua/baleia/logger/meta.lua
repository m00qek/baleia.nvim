---@meta _
--# selene: allow(unused_variable)
error("Cannot require a meta file")

---@class Logger
local logger = {}

-- Shows the log buffer.
--
function logger.show() end

-- Logs an ERROR message.
--
-- Parameters: ~
--   • {message}  Text message
--   • {data}     A lua table that will be pretty printed in the log buffer
---@param message string
---@param data table
function logger.error(message, data) end

-- Logs an WARN message.
--
-- Parameters: ~
--   • {message}  Text message
--   • {data}     A lua table that will be pretty printed in the log buffer
---@param message string
---@param data table
function logger.warn(message, data) end

-- Logs an INFO message.
--
-- Parameters: ~
--   • {message}  Text message
--   • {data}     A lua table that will be pretty printed in the log buffer
---@param message string
---@param data table
function logger.info(message, data) end

-- Logs a DEBUG message.
--
-- Parameters: ~
--   • {message}  Text message
--   • {data}     A lua table that will be pretty printed in the log buffer
---@param message string
---@param data table
function logger.debug(message, data) end

return logger
