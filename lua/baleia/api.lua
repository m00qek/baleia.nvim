local highlights = require("baleia.highlight")
local text = require("baleia.text")

local nvim = require("baleia.nvim")

local api = {}

local function schedule_highlights(opts, buffer, raw_lines, offset)
	local actions = highlights.all(opts, offset, raw_lines)
	if actions then
		nvim.highlight.all(opts.logger, buffer, opts.namespace, actions.definitions, actions.highlights)
	end
end

function api.once(opts, buffer)
	local raw_lines = nvim.buffer.get_lines(opts.logger, buffer)

	if opts.strip_ansi_codes then
		nvim.buffer.set_text(
			opts.logger,
			buffer,
			0,
			0,
			#raw_lines - 1,
			text.lastcolumn(raw_lines),
			text.strip_color_codes(raw_lines)
		)
	end

	schedule_highlights(opts, buffer, raw_lines, {
		global = { column = 0, line = 0 },
	})
end

function api.automatically(opts, buffer)
	nvim.buffer.on_new_lines(opts.logger, buffer, opts.namespace, function(_, _, start_row, end_row)
		local raw_lines = nvim.buffer.get_lines(opts.logger, buffer, start_row, end_row)

		if opts.strip_ansi_codes then
			if nvim.buffer.is_empty(buffer) then
				return
			end

			vim.schedule(function()
				nvim.buffer.set_text(
					opts.logger,
					buffer,
					start_row,
					0,
					end_row - 1,
					text.lastcolumn(raw_lines),
					text.strip_color_codes(raw_lines)
				)
			end)
		end

		schedule_highlights(opts, buffer, raw_lines, {
			global = { column = 0, line = start_row },
		})
	end)
end

function api.buf_set_lines(opts, buffer, start, end_, strict_indexing, raw_lines)
	local lines = opts.strip_ansi_codes and text.strip_color_codes(raw_lines) or raw_lines
	nvim.buffer.set_lines(opts.logger, buffer, start, end_, strict_indexing, lines)

	schedule_highlights(opts, buffer, raw_lines, {
		global = { column = 0, line = start },
	})
end

function api.buf_set_text(opts, buffer, start_row, start_col, end_row, end_col, raw_lines)
	local lines = opts.strip_ansi_codes and text.strip_color_codes(raw_lines) or raw_lines
	nvim.buffer.set_text(opts.logger, buffer, start_row, start_col, end_row, end_col, lines)

	schedule_highlights(opts, buffer, raw_lines, {
		global = { column = 0, line = start_row },
		line = { [1] = { column = start_col } },
	})
end

return api
