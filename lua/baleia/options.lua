local lines = require('baleia.lines')

local options = {}

function options.with_default(opts)
  return {
    strip_sequences = opts.strip_sequences or false,
    line_starts_at = opts.line_starts_at or 1,
    get_lines = opts.get_lines or lines.all(),
    name = opts.name or 'BaleiaColors'
  }
end

function options.conjure()
  local predicate = function(line) return line:sub(1, 1) == ';' end
  return {
    line_starts_at = 3,
    get_lines = lines.take_while(predicate),
    name = 'ConjureLogColors'
  }
end

return options
