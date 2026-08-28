-- Rust LSP + tooling, by haskell-tools' author and the same shape: it owns the
-- rust-analyzer client itself, so after/plugin/lsp.lua deliberately leaves it
-- alone. Filetype plugin — there is no setup() to call; config is via vim.g.rustaceanvim.
local function toggle_inlay_hints(bufnr)
	local filter = { bufnr = bufnr }
	local enabled = vim.lsp.inlay_hint.is_enabled(filter)
	vim.lsp.inlay_hint.enable(not enabled, filter)
	vim.notify("Rust inlay hints " .. (enabled and "off" or "on"))
end

return {
	"mrcjkb/rustaceanvim",
	version = "^9",
	lazy = false,
	init = function()
		vim.g.rustaceanvim = {
			server = {
				default_settings = {
					["rust-analyzer"] = {
						cargo = {
							targetDir = true,
						},
						check = {
							command = "check",
							workspace = false,
							allTargets = false,
						},
					},
				},
			},
		}
	end,
	config = function()
		-- gd/gr/<leader>l* come from the shared LspAttach map in after/plugin/lsp.lua;
		-- these are the rust-only extras. rust-analyzer ships the entire rustc render
		-- (the --> arrows, help:, note:) in the diagnostic's data.rendered field, which
		-- vim.diagnostic.open_float discards in favour of the truncated message — these
		-- two are the only way to see it. Capital R/E because <leader>lr is rename.
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "rust" },
			callback = function(args)
				local function map(lhs, rhs, desc)
					vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
				end
				map("<leader>lt", function()
					toggle_inlay_hints(args.buf)
				end, "Toggle Rust inlay type hints")
				-- Ghostty maps Option+Command+I to F13 so the GUI-only chord can
				-- travel through the terminal and zellij without ambiguity.
				map("<F13>", function()
					toggle_inlay_hints(args.buf)
				end, "Toggle Rust inlay type hints (Option+Command+I)")
				map("<leader>lR", function()
					vim.cmd.RustLsp("renderDiagnostic")
				end, "Render full rustc diagnostic (press 1 in the float to open a split)")
				map("<leader>lE", function()
					vim.cmd.RustLsp("explainError")
				end, "Explain error from the Rust error index (rustc --explain)")
			end,
		})
	end,
}
