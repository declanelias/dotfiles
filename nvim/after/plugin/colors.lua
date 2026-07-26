-- make nord's Normal bg transparent so the terminal (ghostty opacity) shows through
vim.g.nord_disable_background = true

function SetColor(color)
	color = color or "nord"
	vim.cmd.colorscheme(color)

	-- inlay type hints (rust etc.) default to NonText (#3b4252), which blends
	-- into nord0 (#2e3440). bump to frost blue so they're actually visible.
	vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#81a1c1" })
	vim.api.nvim_set_hl(0, "InlayHint", { fg = "#81a1c1" })

	-- shaunsingh/nord.nvim predates the modern JSX/TSX treesitter capture
	-- groups, so it leaves them at Normal fg (#d8dee9) -> React components
	-- render with no color. give them the nord palette explicitly.
	vim.api.nvim_set_hl(0, "@tag.builtin.tsx", { fg = "#81a1c1" }) -- html tags: <div>
	vim.api.nvim_set_hl(0, "@tag.tsx", { fg = "#8fbcbb", bold = true }) -- components: <MyComponent>
	vim.api.nvim_set_hl(0, "@tag.attribute", { fg = "#ebcb8b", italic = true }) -- className, foo
	vim.api.nvim_set_hl(0, "@variable.member", { fg = "#d8dee9" }) -- obj.prop / props
	vim.api.nvim_set_hl(0, "@constructor.tsx", { fg = "#8fbcbb", bold = true })
end

SetColor()
