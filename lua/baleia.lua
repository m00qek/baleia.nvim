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
      end
   }
end

return baleia
