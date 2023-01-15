local highlights = require("baleia.highlight")
local options = require("baleia.options")
local text = require("baleia.text")
local log = require("baleia.log")

local nvim = require("baleia.nvim")

local baleia = {}

local function schedule_highlights(opts, ns, buffer, raw_lines, offset)
   local actions = highlights.all(opts, offset, raw_lines)
   if actions then
      nvim.highlight.all(opts.logger, buffer, ns, actions.definitions, actions.highlights)
   end
end

function baleia.setup(opts)
   opts = options.with_default(opts)

   local ns = nvim.create_namespace(opts.name)

   opts.logger = log.NULL_LOGGER
   if opts.log then
      opts.logger = log.logger(opts.name .. 'Log', ns, opts.log)
   end

   return {
      once = function(buffer)
         local raw_lines = nvim.buffer.get_lines(opts.logger, buffer)

         if opts.strip_ansi_codes then
            nvim.buffer.set_text(opts.logger,
                                 buffer,
                                 0,
                                 0,
                                 #raw_lines - 1,
                                 text.lastcolumn(raw_lines),
                                 text.strip_color_codes(raw_lines))
         end

         schedule_highlights(opts, ns, buffer, raw_lines, {
            global = { column = 0, line = 0 }
         })
      end,
      automatically = function(buffer)
         nvim.buffer.on_new_lines(opts.logger, buffer, ns, function(_, _, start_row, end_row)
            local raw_lines = nvim.buffer.get_lines(opts.logger, buffer, start_row, end_row)

            if opts.strip_ansi_codes then
               if nvim.buffer.is_empty(buffer) then
                     return
               end

               vim.schedule(function()
                  nvim.buffer.set_text(opts.logger,
                                       buffer,
                                       start_row,
                                       0,
                                       end_row - 1,
                                       text.lastcolumn(raw_lines),
                                       text.strip_color_codes(raw_lines))
               end)
            end

            schedule_highlights(opts, ns, buffer, raw_lines, {
               global = { column = 0, line = start_row }
            })
         end)
      end,
      buf_set_lines = function(buffer, start, end_, strict_indexing, raw_lines)
         local lines = opts.strip_ansi_codes and text.strip_color_codes(raw_lines) or raw_lines
         nvim.buffer.set_lines(opts.logger, buffer, start, end_, strict_indexing, lines)

         schedule_highlights(opts, ns, buffer, raw_lines, {
            global = { column = 0, line = start }
         })
      end,
      buf_set_text = function(buffer, start_row, start_col, end_row, end_col, raw_lines)
         local lines = opts.strip_ansi_codes and text.strip_color_codes(raw_lines) or raw_lines
         nvim.buffer.set_text(opts.logger, buffer, start_row, start_col, end_row, end_col, lines)

         schedule_highlights(opts, ns, buffer, raw_lines, {
            global = { column = 0, line = start_row },
            line = { [1] = { column = start_col } },
         })
      end,
      logger = opts.logger,
   }
end

return baleia
