local langs = { "lua", "typescript", "python", "rust" }

require("nvim-treesitter").setup({
	install_dir = vim.fn.stdpath('data') .. '/site'
})

require("nvim-treesitter").install(langs)

vim.api.nvim_create_autocmd('FileType', {
	pattern = langs,
	callback = function()
		local ok = pcall(vim.treesitter.start)
		if ok then
			vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})
