return {
	"epwalsh/obsidian.nvim",
	version = "*",
	lazy = true,
	ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "current-buffer",
				path = function()
					local buffer = vim.api.nvim_buf_get_name(0)
					if buffer == "" then
						return vim.fn.getcwd()
					end
					return assert(vim.fs.dirname(buffer))
				end,
			},
		},
		completion = {
			nvim_cmp = false,
			min_chars = 2,
		},
		ui = {
			enable = false, -- markview.nvim renders markdown; see lazy/markview.lua
		},
	},
}
