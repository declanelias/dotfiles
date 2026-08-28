return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "black" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			json = { "prettierd", "prettier", stop_after_first = true },
			jsonc = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "prettierd", "prettier", stop_after_first = true },
			markdown = { "prettierd", "prettier", stop_after_first = true },
			["markdown.mdx"] = { "prettierd", "prettier", stop_after_first = true },
			toml = { "taplo" },
			sh = { "shfmt" },
			rust = { "rustfmt" },
			c = { "clang-format" },
			cpp = { "clang-format" },
		},
		format_on_save = {
			timeout_ms = 2000,
			lsp_format = "fallback",
		},
	},
}
