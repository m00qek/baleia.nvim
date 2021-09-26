local highlights = require("baleia.highlight")
local options = require("baleia.options")
local text = require("baleia.text")

local nvim_highlight = require("baleia.nvim.highlight")
local nvim = require("baleia.nvim")

local baleia = {}

local function schedule_highlights(opts, ns, buffer, raw_lines, offset)
   vim.schedule(function()
      local actions = highlights.all(opts, offset, raw_lines)
      if actions then
         nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
      end
   end)
end

function baleia.setup(opts)
   opts = options.with_default(opts)

   local ns = nvim.create_namespace(opts.name)

   return {
      once = function(buffer)
         local raw_lines = nvim.get_lines(buffer)

         if opts.strip_ansi_codes then
            vim.api.nvim_buf_set_text(buffer,
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
         nvim.execute_on_new_lines(buffer, ns, function(_, _, start_row, end_row)
            local raw_lines = nvim.get_lines(buffer, start_row, end_row)

            if opts.strip_ansi_codes then
               vim.schedule(function()
                  vim.api.nvim_buf_set_text(buffer,
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
         vim.api.nvim_buf_set_lines(buffer, start, end_, strict_indexing, lines)

         schedule_highlights(opts, ns, buffer, raw_lines, {
            global = { column = 0, line = start }
         })
      end,
      buf_set_text = function(buffer, start_row, start_col, end_row, end_col, raw_lines)
         local lines = opts.strip_ansi_codes and text.strip_color_codes(raw_lines) or raw_lines
         vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, lines)

         schedule_highlights(opts, ns, buffer, raw_lines, {
            global = { column = 0, line = start_row },
            line = { [1] = { column = start_col } },
         })
      end,
   }
end

return baleia
