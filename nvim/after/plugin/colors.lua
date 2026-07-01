-- make nord's Normal bg transparent so the terminal (ghostty opacity) shows through
vim.g.nord_disable_background = true

function SetColor(color)
	color = color or "nord"
	vim.cmd.colorscheme(color)

	-- inlay type hints (rust etc.) default to NonText (#3b4252), which blends
	-- into nord0 (#2e3440). bump to frost blue so they're actually visible.
	vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#81a1c1" })
	vim.api.nvim_set_hl(0, "InlayHint", { fg = "#81a1c1" })
end

SetColor()
