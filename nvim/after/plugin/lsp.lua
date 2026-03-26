require("mason").setup({
  ui = {
        icons = {
            package_installed = "",
            package_pending = "",
            package_uninstalled = "",
        },
  }
})

require("mason-lspconfig").setup({
	ensure_installed = {
		"lua_ls",
		"ts_ls",
		"pyright",
    "clangd",
	},
})

-- Lua
vim.lsp.config.lua_ls = {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
}

-- TypeScript/JavaScript
vim.lsp.config.ts_ls = {}

-- Python
vim.lsp.config.pyright = {}

-- Rust: managed by rustaceanvim, not configured here

-- Enable the servers
vim.lsp.enable({ "lua_ls", "ts_ls", "pyright" })

-- Keybindings when LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local opts = { buffer = args.buf }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts) -- go to definition
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show type/docs popup
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- rename symbol across project
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts) -- show code actions (fixes, refactors)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts) -- find all references
		vim.keymap.set("n", "<leader>ds", vim.diagnostic.open_float, opts) -- show full diagnostic in floating window
		vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous error/warning
		vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next error/warning
		vim.lsp.inlay_hint.enable(true, { bufnr = args.buf }) -- show inline type hints (like vscode)
	end,
})

vim.diagnostic.config({
	virtual_text = true, -- show error/warning text inline at end of line
	signs = true, -- show icons in the sign column
	underline = true, -- underline the problematic code
})
