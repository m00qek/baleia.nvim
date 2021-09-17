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
         local range = lines.all()(nvim.get_lines, buffer)
         local offset = { column = 0, line = range.first - 1 }
         local actions = highlights.all(opts, offset, range.lines)

         nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
      end,
      automatically = function(buffer)
         nvim.execute_on_change(buffer, ns, function(_, _, firstline, lastline)
            local range = opts.get_lines(nvim.get_lines, buffer, firstline, lastline)
            local offset = { column = 0, line = range.first - 1 }
            local actions = highlights.all(opts, offset, range.lines)

            nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
         end)
      end,
      buf_set_lines = function(buffer, start, end_, strict_indexing, replacement)
         local range = lines.list(start + 1, replacement)
         local offset = { column = 2, line = range.first - 1 }
         local actions = highlights.all(options.merge(opts, { strip_ansi_codes = true }), offset, range.lines)

         vim.api.nvim_buf_set_lines(buffer, start, end_, strict_indexing, actions.lines)

         nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
      end,
      buf_set_text = function(buffer, start_row, start_col, end_row, end_col, replacement)
         local range = lines.list(start_row + 1, replacement)
         local offset = { column = 0, line = range.first - 1 }
         local actions = highlights.all(options.merge(opts, { strip_ansi_codes = true }), offset, range.lines)

         vim.api.nvim_buf_set_lines(buffer, start_row, start_col, end_row, end_col, replacement)

         nvim_highlight.all(buffer, ns, actions.definitions, actions.highlights)
      end,
   }
end

return baleia
