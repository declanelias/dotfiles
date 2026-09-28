return {
	"zenbones-theme/zenbones.nvim",
	dependencies = {
		"rktjmp/lush.nvim",
	},
	-- Apply the theme before eager UI plugins compute their highlight groups.
	lazy = false,
	priority = 1000,
	init = function()
		vim.o.background = "dark"
		vim.g.zenwritten = {
			transparent_background = true,
		}
	end,
}
