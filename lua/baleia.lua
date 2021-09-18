local highlights = require("baleia.highlight")
local options = require("baleia.options")

local nvim_highlight = require("baleia.nvim.highlight")
local nvim = require("baleia.nvim")

local baleia = {}

function baleia.setup(opts)
   opts = options.with_default(opts)

   local ns = nvim.create_namespace(opts.name)

   return {
      once = function(buffer)
         local raw_lines = nvim.get_lines(buffer)
         local offset = { global = { column = 0, line = 0 } }

         local actions = highlights.all(opts, offset, raw_lines)
         if not actions then
            return
         end

         if opts.strip_ansi_codes then
            local lastline = raw_lines[#raw_lines]
            vim.api.nvim_buf_set_text(buffer, 0, 0, #raw_lines - 1, #lastline, actions.lines)
         end
         nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
      end,
      automatically = function(buffer)
         nvim.execute_on_new_lines(buffer, ns, function(_, _, start_row, end_row)
            local raw_lines = nvim.get_lines(buffer, start_row, end_row)
            local offset = { global = { column = 0, line = start_row - 1 } }

            local actions = highlights.all(opts, offset, raw_lines)
            if not actions then
               return
            end

            vim.schedule(function()
               if opts.strip_ansi_codes then
                  local lastline = raw_lines[#raw_lines]
                  vim.api.nvim_buf_set_text(buffer, start_row - 1, 0, end_row - 1, #lastline, actions.lines)
               end
               nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
            end)
         end)
      end,
      buf_set_lines = function(buffer, start, end_, strict_indexing, raw_lines)
         local offset = { global = { column = 0, line = start } }

         local actions = highlights.all(opts, offset, raw_lines)
         if not actions then
            vim.api.nvim_buf_set_lines(buffer, start, end_, strict_indexing, raw_lines)
            return
         end

         vim.api.nvim_buf_set_lines(buffer, start, end_, strict_indexing, actions.lines)
         vim.schedule(function()
            nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
         end)
      end,
      buf_set_text = function(buffer, start_row, start_col, end_row, end_col, raw_lines)
         local offset = {
            global = { column = 0, line = start_row },
            line = { [1] = { column = start_col } },
         }

         local actions = highlights.all(opts, offset, raw_lines)
         if not actions then
            vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, raw_lines)
            return
         end

         vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, actions.lines)
         vim.schedule(function()
            nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
         end)
      end,
   }
end

return baleia
