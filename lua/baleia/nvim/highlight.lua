local module = {}

local nvim = {
	buffer = require("baleia/nvim/buffer"),
	api = require("baleia/nvim/api"),
}

---@param logger Logger
---@param buffer integer
---@param namespace integer
---@param highlights table<string, HighlightAttributes>
---@param marks table<Mark>
function module.all(logger, buffer, namespace, highlights, marks)
	vim.schedule(function()
		local hl = nvim.api.highlights(logger, 0)
		for name, attributes in pairs(highlights) do
			if hl.undefined(name) then
				nvim.buffer.create_highlight(logger, name, attributes)
			end
		end
	end)

	vim.schedule(function()
		for _, mark in ipairs(marks) do
			nvim.buffer.add_highlight(
				logger,
				buffer,
				namespace,
				mark.highlight,
				mark.line - 1,
				mark.firstcolumn - 1,
				mark.lastcolumn
			)
		end
	end)
end

return module
