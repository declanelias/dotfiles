-- parser names (what gets installed) vs filetypes (what triggers highlighting):
-- typescriptreact uses the tsx parser, javascriptreact uses the javascript parser
local parsers = {
	"bash",
	"haskell",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"python",
	"rust",
	"toml",
	"tsx",
	"typescript",
	"yaml",
}
local filetypes = {
	"haskell",
	"javascript",
	"javascriptreact",
	"json",
	"jsonc",
	"lua",
	"markdown",
	"python",
	"rust",
	"sh",
	"toml",
	"typescript",
	"typescriptreact",
	"yaml",
}

require("nvim-treesitter").setup({
	install_dir = vim.fn.stdpath("data") .. "/site",
})

require("nvim-treesitter").install(parsers)

vim.api.nvim_create_autocmd("FileType", {
	pattern = filetypes,
	callback = function()
		local ok = pcall(vim.treesitter.start)
		if ok then
			vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})
