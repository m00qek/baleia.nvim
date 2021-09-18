local highlights = require("baleia.highlight")
local options = require("baleia.options")
local lines = require("baleia.lines")

local nvim_highlight = require("baleia.nvim.highlight")
local nvim = require("baleia.nvim")

local baleia = {}

function baleia.setup(opts)
   opts = options.with_default(opts)

   local ns = nvim.create_namespace(opts.name)

   return {
      once = function(buffer)
         local original = lines.all()(nvim.get_lines, buffer)
         local offset = { global = { column = 0, line = original.first - 1 } }
         local actions = highlights.all(opts, offset, original.lines)
         if not actions then
            return
         end

         local line = original.lines[#original.lines]
         if opts.strip_ansi_codes then
            vim.api.nvim_buf_set_text(buffer, 0, 0, #original.lines - 1, #line, actions.lines)
         end

         nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
      end,
      automatically = function(buffer)
         nvim.execute_on_new_lines(buffer, ns, function(_, _, firstline, lastline)
            local original = {
               lines = nvim.get_lines(buffer, firstline, lastline),
               first = firstline
            }
            local offset = { global = { column = 0, line = original.first - 1 } }
            local actions = highlights.all(opts, offset, original.lines)
            if not actions then
               return
            end

            vim.schedule(function()
               if opts.strip_ansi_codes then
                  vim.api.nvim_buf_call(buffer, function()
                     local line = original.lines[#original.lines]
                     vim.api.nvim_buf_set_text(buffer, firstline - 1, 0, lastline - 1, #line, actions.lines)
                  end)
               end
               nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
            end)
         end)
      end,
      buf_set_lines = function(buffer, start, end_, strict_indexing, replacement)
         local range = lines.list(start + 1, replacement)
         local offset = { global = { column = 0, line = range.first - 1 } }
         local actions = highlights.all(opts, offset, range.lines)

         vim.api.nvim_buf_set_lines(buffer, start, end_, strict_indexing, actions.lines)

         vim.schedule(function()
            nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
         end)
      end,
      buf_set_text = function(buffer, start_row, start_col, end_row, end_col, replacement)
         local range = lines.list(start_row + 1, replacement)
         local offset = {
            global = { column = 0, line = range.first - 1 },
            line = { [1] = { column = start_col } },
         }
         local actions = highlights.all(opts, offset, range.lines)

         vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, actions.lines)

         vim.schedule(function()
            nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
         end)
      end,
   }
end

return baleia
