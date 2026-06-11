-- parser names (what gets installed) vs filetypes (what triggers highlighting):
-- typescriptreact uses the tsx parser, javascriptreact uses the javascript parser
local parsers = { "lua", "typescript", "tsx", "javascript", "python", "rust" }
local filetypes = { "lua", "typescript", "typescriptreact", "javascript", "javascriptreact", "python", "rust" }

require("nvim-treesitter").setup({
	install_dir = vim.fn.stdpath('data') .. '/site'
})

require("nvim-treesitter").install(parsers)

vim.api.nvim_create_autocmd('FileType', {
	pattern = filetypes,
	callback = function()
		local ok = pcall(vim.treesitter.start)
		if ok then
			vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})
