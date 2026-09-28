-- mason itself is set up by its lazy spec (lua/declan/lazy/mason.lua)
require("mason-lspconfig").setup({
	ensure_installed = {
		"lua_ls",
		"ts_ls",
		"pyright",
		"clangd",
		"eslint",
		"jsonls",
		"taplo",
		"yamlls",
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

-- C/C++
vim.lsp.config.clangd = {}

-- Project linting and config-file schemas. Each server still uses its own root
-- markers, so these only attach in projects where they are relevant.
vim.lsp.config.eslint = {}
vim.lsp.config.jsonls = {}
vim.lsp.config.taplo = {}
vim.lsp.config.yamlls = {}

-- Rust: managed by rustaceanvim, not configured here
-- Haskell: managed by haskell-tools, not configured here

-- Advertise foldingRange support to every server (consumed by nvim-ufo's lsp provider).
-- Deep-merges with blink.cmp's capabilities rather than replacing them.
vim.lsp.config("*", {
	capabilities = {
		textDocument = {
			foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			},
		},
	},
})

-- Enable the servers
vim.lsp.enable({ "lua_ls", "ts_ls", "pyright", "clangd", "eslint", "jsonls", "taplo", "yamlls" })

-- Neovim 0.12.x can retain an inlay hint after its line becomes shorter, then
-- abort the window decoration pass while diagnostics are being redrawn with
-- "Invalid 'col': out of range" (neovim/neovim#39772). The upstream fix is on
-- master rather than the 0.12 release branch. Drop only those stale hints so
-- diagnostic virtual text/lines and all valid inlay hints keep rendering.
local version = vim.version()
if version.major == 0 and version.minor == 12 and not vim.g.declan_inlay_hint_bounds_guard then
	vim.g.declan_inlay_hint_bounds_guard = true
	local inlay_hint_namespace = vim.api.nvim_create_namespace("nvim.lsp.inlayhint")
	local set_extmark = vim.api.nvim_buf_set_extmark

	vim.api.nvim_buf_set_extmark = function(bufnr, namespace, line, col, opts)
		if namespace == inlay_hint_namespace and opts and opts.virt_text_pos == "inline" then
			local text = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
			if not text or col > #text then
				return 0
			end
		end

		return set_extmark(bufnr, namespace, line, col, opts)
	end
end

-- Delete nvim's default gr-prefixed LSP maps (grr/grn/gra/gri/grt) so the
-- buffer-local `gr` below fires without waiting out the chord timeout
for _, lhs in ipairs({ "grr", "grn", "gra", "gri", "grt" }) do
	pcall(vim.keymap.del, "n", lhs)
end
pcall(vim.keymap.del, "x", "gra")

-- Keybindings when LSP attaches. Neovim's default K hover remains intact.
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local function map(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
		end
		map("gd", vim.lsp.buf.definition, "Go to definition")
		map("gi", vim.lsp.buf.implementation, "Go to implementation")
		map("gy", vim.lsp.buf.type_definition, "Go to type definition")
		map("gr", vim.lsp.buf.references, "Find references")
		map("<leader>li", vim.lsp.buf.incoming_calls, "Incoming calls")
		map("<leader>lo", vim.lsp.buf.outgoing_calls, "Outgoing calls")
		map("[d", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end, "Previous diagnostic")
		map("]d", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end, "Next diagnostic")
		map("<leader>lr", vim.lsp.buf.rename, "Rename symbol")
		map("<leader>la", vim.lsp.buf.code_action, "Code action")
		map("<leader>ld", vim.diagnostic.open_float, "Diagnostic float")
		vim.lsp.inlay_hint.enable(true, { bufnr = args.buf }) -- show inline type hints (like vscode)
	end,
})

local function split_at_display_width(text, width)
	local chunks = {}
	local chunk = ""

	for index = 0, vim.fn.strchars(text) - 1 do
		local char = vim.fn.strcharpart(text, index, 1)
		if chunk ~= "" and vim.fn.strdisplaywidth(chunk .. char) > width then
			table.insert(chunks, chunk)
			chunk = char
		else
			chunk = chunk .. char
		end
	end

	if chunk ~= "" then
		table.insert(chunks, chunk)
	end
	return chunks
end

local function wrap_diagnostic_line(line, width)
	local wrapped = {}
	local current = ""

	for word in line:gmatch("%S+") do
		local candidate = current == "" and word or current .. " " .. word
		if vim.fn.strdisplaywidth(candidate) <= width then
			current = candidate
		else
			if current ~= "" then
				table.insert(wrapped, current)
			end

			local chunks = split_at_display_width(word, width)
			for index = 1, #chunks - 1 do
				table.insert(wrapped, chunks[index])
			end
			current = chunks[#chunks] or ""
		end
	end

	table.insert(wrapped, current)
	return wrapped
end

local function format_virtual_line(diagnostic)
	local winid = vim.fn.bufwinid(diagnostic.bufnr)
	if winid == -1 then
		winid = vim.api.nvim_get_current_win()
	end

	local wininfo = vim.fn.getwininfo(winid)[1]
	local source_line = vim.api.nvim_buf_get_lines(diagnostic.bufnr, diagnostic.lnum, diagnostic.lnum + 1, false)[1] or ""
	local diagnostic_column = vim.fn.strdisplaywidth(source_line:sub(1, diagnostic.col))
	-- Native virtual lines reserve six cells for their branch marker but do not
	-- wrap. Insert newlines before rendering so messages stay inside the window.
	local width = math.max(1, vim.api.nvim_win_get_width(winid) - wininfo.textoff - diagnostic_column - 6)
	local message = diagnostic.code and string.format("%s: %s", diagnostic.code, diagnostic.message) or diagnostic.message
	local wrapped = {}

	for line in (message .. "\n"):gmatch("(.-)\n") do
		vim.list_extend(wrapped, wrap_diagnostic_line(line, width))
	end
	return table.concat(wrapped, "\n")
end

vim.diagnostic.config({
	update_in_insert = true, -- surface LSP diagnostics while typing instead of waiting for Normal mode
	-- Keep compact diagnostics inline until the cursor reaches their line, then
	-- replace the inline text with the full wrapped message below that line.
	virtual_text = { current_line = false },
	virtual_lines = { current_line = true, format = format_virtual_line },
	signs = true, -- show icons in the sign column
	underline = true, -- underline the problematic code
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client:supports_method("textDocument/documentHighlight") then
			local group = vim.api.nvim_create_augroup("lsp-highlight-" .. args.buf, { clear = true })
			vim.api.nvim_create_autocmd("CursorHold", {
				buffer = args.buf,
				group = group,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd("CursorMoved", {
				buffer = args.buf,
				group = group,
				callback = vim.lsp.buf.clear_references,
			})
		end
	end,
})
