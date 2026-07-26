return {
	"kevinhwang91/nvim-ufo",
	dependencies = { "kevinhwang91/promise-async" },
	event = "BufReadPost",
	init = function()
		-- ufo needs a high foldlevel so nothing auto-collapses on open.
		-- (A low foldlevel makes ufo re-close folds every time the LSP resends
		-- ranges — the classic "my folds keep collapsing" bug. Keep both at 99.)
		vim.o.foldcolumn = "1"
		vim.o.foldlevel = 99
		vim.o.foldlevelstart = 99
		vim.o.foldenable = true -- NOTE: `zi` toggles this off; if nothing collapses, that's why
		-- arrows in the foldcolumn instead of raw digits (single-char, no Nerd Font needed)
		vim.opt.fillchars:append({ foldopen = "▾", foldclose = "▸", foldsep = " " })
	end,
	config = function()
		local ufo = require("ufo")

		-- compact " 󰁂 N " suffix showing folded line count, truncated to width
		local handler = function(virtText, lnum, endLnum, width, truncate)
			local newVirtText = {}
			local suffix = (" 󰁂 %d "):format(endLnum - lnum)
			local sufWidth = vim.fn.strdisplaywidth(suffix)
			local targetWidth = width - sufWidth
			local curWidth = 0
			for _, chunk in ipairs(virtText) do
				local chunkText = chunk[1]
				local chunkWidth = vim.fn.strdisplaywidth(chunkText)
				if targetWidth > curWidth + chunkWidth then
					table.insert(newVirtText, chunk)
				else
					chunkText = truncate(chunkText, targetWidth - curWidth)
					local hlGroup = chunk[2]
					table.insert(newVirtText, { chunkText, hlGroup })
					chunkWidth = vim.fn.strdisplaywidth(chunkText)
					if curWidth + chunkWidth < targetWidth then
						suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
					end
					break
				end
				curWidth = curWidth + chunkWidth
			end
			table.insert(newVirtText, { suffix, "MoreMsg" })
			return newVirtText
		end

		-- ufo's built-in chain only supports two providers and lets the second
		-- one's UfoFallbackException escape as an unhandled rejection, so chain
		-- lsp -> treesitter -> indent manually; indent never throws
		local function selectorWithFallback(bufnr)
			local function handleFallbackException(err, providerName)
				if type(err) == "string" and err:match("UfoFallbackException") then
					return ufo.getFolds(bufnr, providerName)
				else
					return require("promise").reject(err)
				end
			end
			return ufo.getFolds(bufnr, "lsp")
				:catch(function(err)
					return handleFallbackException(err, "treesitter")
				end)
				:catch(function(err)
					return handleFallbackException(err, "indent")
				end)
		end

		ufo.setup({
			fold_virt_text_handler = handler,
			-- LSP folds (lua_ls/ts_ls/pyright) with treesitter as fallback;
			-- ufo ships its own folds.scm queries so rust/etc. fold without an LSP provider
			provider_selector = function(_, filetype, buftype)
				-- disable ufo on special buffers (oil, etc.)
				if buftype ~= "" or filetype == "oil" then
					return ""
				end
				return selectorWithFallback
			end,
		})

		-- ── Whole-buffer fold control (mutates foldlevel) ──────────────────
		-- zR/zM must go through ufo's APIs; the native versions fight ufo's
		-- manual folds and desync the display.
		-- Relative one-level stepping. ufo pins foldlevel at 99 and closeFoldsWith()
		-- does NOT write it back, so we CANNOT read vim.wo.foldlevel to know where we
		-- are — we track the intended display level ourselves in a window-local var.
		-- closeFoldsWith(n) closes every fold DEEPER than level n; n=0 folds the whole
		-- file, n=max shows everything.
		local function max_level()
			local m = 0
			for lnum = 1, vim.fn.line("$") do
				m = math.max(m, vim.fn.foldlevel(lnum))
			end
			return m
		end
		local function get_level(m)
			-- nil (fresh buffer, everything open) == fully unfolded == max depth
			return vim.w.ufo_foldlevel or m
		end

		vim.keymap.set("n", "zR", function()
			ufo.openAllFolds()
			vim.w.ufo_foldlevel = max_level()
		end, { desc = "Fold: open ALL" })
		vim.keymap.set("n", "zM", function()
			ufo.closeAllFolds()
			vim.w.ufo_foldlevel = 0
		end, { desc = "Fold: close ALL" })

		vim.keymap.set("n", "zm", function()
			local m = max_level()
			local lvl = math.max(math.min(get_level(m), m) - 1, 0)
			ufo.closeFoldsWith(lvl)
			vim.w.ufo_foldlevel = lvl
		end, { desc = "Fold: close one MORE level (whole file)" })
		vim.keymap.set("n", "zr", function()
			local m = max_level()
			local lvl = math.min(get_level(m) + 1, m)
			if lvl >= m then
				ufo.openAllFolds()
			else
				ufo.closeFoldsWith(lvl)
			end
			vim.w.ufo_foldlevel = lvl
		end, { desc = "Fold: reveal one more level (whole file)" })

		-- ── Single-fold control (the fold UNDER THE CURSOR) ────────────────
		-- These are native and already work with ufo's manual folds; mapping
		-- them to themselves just documents them so which-key surfaces them.
		-- This is your "collapse just this one" set.
		vim.keymap.set("n", "za", "za", { desc = "Fold: toggle this one" })
		vim.keymap.set("n", "zc", "zc", { desc = "Fold: collapse this one" })
		vim.keymap.set("n", "zC", "zC", { desc = "Fold: collapse this one + all nested" })
		vim.keymap.set("n", "zo", "zo", { desc = "Fold: open this one" })
		vim.keymap.set("n", "zO", "zO", { desc = "Fold: open this one + all nested" })
		-- <Tab> = one-key toggle of the fold under the cursor (most-used op)
		vim.keymap.set("n", "<Tab>", "za", { desc = "Fold: toggle this one" })

		-- peek a closed fold; fall back to LSP hover (covers non-LSP buffers,
		-- LSP buffers override this with the buffer-local K set in after/plugin/lsp.lua)
		vim.keymap.set("n", "K", function()
			if not ufo.peekFoldedLinesUnderCursor() then
				vim.lsp.buf.hover()
			end
		end, { desc = "Peek fold or hover" })
	end,
}
