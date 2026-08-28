-- Buffer-based file manager: a directory opens as an editable buffer. Rename a
-- line to rename a file, dd to delete, p to move, add a line to create; :w applies.
-- Replaces neo-tree. https://github.com/stevearc/oil.nvim

-- Cache ignored entries per directory. Oil asks this once for every visible
-- entry, so running git once per directory avoids a process per file. Using
-- is_always_hidden keeps generated files hidden even though dotfiles are shown.
local function new_gitignore_cache()
	return setmetatable({}, {
		__index = function(cache, dir)
			local result = vim.system(
				{ "git", "ls-files", "--ignored", "--exclude-standard", "--others", "--directory" },
				{ cwd = dir, text = true }
			):wait()
			local ignored = {}
			if result.code == 0 then
				for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
					ignored[line:gsub("/$", "")] = true
				end
			end
			rawset(cache, dir, ignored)
			return ignored
		end,
	})
end

return {
	"stevearc/oil.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		{
			"malewicz1337/oil-git.nvim",
			opts = {
				show_directory_highlights = true,
				show_ignored_files = false,
				show_ignored_directories = false,
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
		},
		keymaps = {
			-- zellij (clear-defaults) swallows <C-s>/<C-h>/<C-t>/<C-p> before nvim
			-- sees them, so oil's split/tab/preview opens are unreachable. Mirror
			-- them onto the g-prefix oil already uses for gx/gs/g./g?
			["gv"] = { "actions.select", opts = { vertical = true }, desc = "Open in vsplit" },
			["gh"] = { "actions.select", opts = { horizontal = true }, desc = "Open in split" },
			["gt"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },
			["gp"] = { "actions.preview", desc = "Preview" },
			["q"] = { "actions.close", mode = "n" },
		},
	},
	keys = {
		-- in-window, NOT a float: oil takes over the current buffer and close()
		-- puts the old one back, so splits/jumps/<leader>w all behave normally
		{
			"-",
			function()
				require("oil").open()
			end,
			desc = "Open parent dir (oil)",
		},
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
	config = function(_, opts)
		local gitignore_cache = new_gitignore_cache()
		opts.view_options.is_always_hidden = function(name, bufnr)
			if name == ".git" then
				return true
			end
			local dir = require("oil").get_current_dir(bufnr)
			return dir ~= nil and gitignore_cache[dir][name] == true
		end

		-- Refreshing Oil also refreshes the gitignore cache, so newly generated
		-- or newly unignored files appear correctly without restarting Neovim.
		local refresh = require("oil.actions").refresh
		local original_refresh = refresh.callback
		refresh.callback = function(...)
			gitignore_cache = new_gitignore_cache()
			return original_refresh(...)
		end

		require("oil").setup(opts)
	end,
}
