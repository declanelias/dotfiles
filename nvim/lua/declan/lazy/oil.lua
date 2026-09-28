-- Buffer-based file manager: a directory opens as an editable buffer. Rename a
-- line to rename a file, dd to delete, p to move, add a line to create; :w applies.
-- Replaces neo-tree. https://github.com/stevearc/oil.nvim

return {
	"stevearc/oil.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		{
			"malewicz1337/oil-git.nvim",
			opts = {
				show_directory_highlights = true,
				show_ignored_files = true,
				show_ignored_directories = true,
				symbol_position = "eol",
			},
		},
		{
			"JezerM/oil-lsp-diagnostics.nvim",
			opts = {},
		},
	},
	lazy = false, -- load at startup so it can hijack netrw
	opts = {
		default_file_explorer = true, -- take over netrw (as neo-tree did)
		delete_to_trash = true,
		view_options = {
			show_hidden = true, -- neo-tree showed dotfiles; keep them visible
			-- Show Git-ignored entries too (oil-git marks them); only .git stays out.
			is_always_hidden = function(name)
				return name == ".git"
			end,
		},
		keymaps = {
			-- Convenient aliases for Oil's Control-key split/tab/preview defaults;
			-- unlock-first Zellij lets both forms reach Neovim.
			["gv"] = { "actions.select", opts = { vertical = true }, desc = "Open in vsplit" },
			["gh"] = { "actions.select", opts = { horizontal = true }, desc = "Open in split" },
			["gt"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },
			["gp"] = { "actions.preview", desc = "Preview" },
			["q"] = { "actions.close", mode = "n", desc = "Close Oil" },
		},
	},
	keys = {
		{
			"<leader>e",
			function()
				local oil = require("oil")
				if vim.bo.filetype == "oil" then
					oil.close()
				else
					oil.open()
				end
			end,
			desc = "File explorer (oil)",
		},
	},
}
