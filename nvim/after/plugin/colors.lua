-- markview blends its heading/callout backgrounds against Normal's bg, but the
-- colorscheme leaves Normal transparent. Point it at the published Zenwritten
-- background that Ghostty paints behind Neovim.
vim.g.markview_dark_bg = "#191919"

function SetColor(color)
	color = color or "zenwritten"
	vim.cmd.colorscheme(color)

	-- oil-git initializes before the colorscheme, which clears its highlight
	-- groups while leaving the status symbols in place. Restore familiar VS Code
	-- Git decoration colors after every colorscheme change.
	local oil_git_colors = {
		OilGitAdded = "#81b88b",
		OilGitModified = "#e2c08d",
		OilGitModifiedStaged = "#e2c08d",
		OilGitModifiedUnstaged = "#e2c08d",
		OilGitRenamed = "#73c991",
		OilGitCopied = "#73c991",
		OilGitDeleted = "#c74e39",
		OilGitConflict = "#e4676b",
		OilGitUntracked = "#73c991",
		OilGitIgnored = "#8c8c8c",
		OilGitBranch = "#8db9e2",
	}
	for group, foreground in pairs(oil_git_colors) do
		vim.api.nvim_set_hl(0, group, { fg = foreground })
	end
end

SetColor()
