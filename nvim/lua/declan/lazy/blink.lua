return {
	"saghen/blink.cmp",
	version = "1.*",
	opts = {
		keymap = { preset = "default" },
		appearance = {
			nerd_font_variant = "mono",
		},
		completion = {
			documentation = { auto_show = true },
		},
		sources = {
			-- The built-in snippets source uses vim.snippet; no separate snippet
			-- engine is needed, and LSP/custom snippets can use Tab placeholders.
			default = { "lsp", "path", "snippets", "buffer" },
		},
	},
}
