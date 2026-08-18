-- Haskell LSP + tooling, by rustaceanvim's author and the same shape: it owns
-- the hls client itself, so after/plugin/lsp.lua deliberately leaves it alone.
-- Filetype plugin — there is no setup() to call; config is via vim.g.haskell_tools.
return {
	"mrcjkb/haskell-tools.nvim",
	version = "^10",
	lazy = false,
	config = function()
		-- gd/gr/<leader>l* come from the shared LspAttach map in after/plugin/lsp.lua;
		-- these are the haskell-only extras hls alone doesn't give you.
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "haskell", "lhaskell", "cabal", "cabalproject" },
			callback = function(args)
				local ht = require("haskell-tools")
				local function map(lhs, rhs, desc)
					vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
				end
				map("<leader>lhh", ht.hoogle.hoogle_signature, "Hoogle signature search")
				map("<leader>lhe", ht.lsp.buf_eval_all, "Evaluate code snippets in comments")
				map("<leader>lhp", ht.project.open_project_file, "Open project file (cabal/package.yaml)")
				map("<leader>lhr", ht.repl.toggle, "GHCi repl for package")
				map("<leader>lhf", function()
					ht.repl.toggle(vim.api.nvim_buf_get_name(0))
				end, "GHCi repl for this file")
				map("<leader>lhq", ht.repl.quit, "Quit GHCi repl")
			end,
		})
	end,
}
