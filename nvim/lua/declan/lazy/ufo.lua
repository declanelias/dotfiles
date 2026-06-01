return {
	"kevinhwang91/nvim-ufo",
	dependencies = { "kevinhwang91/promise-async" },
	event = "BufReadPost",
	init = function()
		-- ufo needs a high foldlevel so nothing auto-collapses on open
		vim.o.foldcolumn = "1"
		vim.o.foldlevel = 99
		vim.o.foldlevelstart = 99
		vim.o.foldenable = true
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

		ufo.setup({
			fold_virt_text_handler = handler,
			-- LSP folds (lua_ls/ts_ls/pyright) with treesitter as fallback;
			-- ufo ships its own folds.scm queries so rust/etc. fold without an LSP provider
			provider_selector = function(_, _, _)
				return { "lsp", "treesitter" }
			end,
		})

		vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "Open all folds" })
		vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "Close all folds" })
		vim.keymap.set("n", "zr", ufo.openFoldsExceptKinds, { desc = "Open folds except kinds" })
		vim.keymap.set("n", "zm", ufo.closeFoldsWith, { desc = "Close folds with level" })

		-- peek a closed fold; fall back to LSP hover (covers non-LSP buffers,
		-- LSP buffers override this with the buffer-local K set in after/plugin/lsp.lua)
		vim.keymap.set("n", "K", function()
			if not ufo.peekFoldedLinesUnderCursor() then
				vim.lsp.buf.hover()
			end
		end, { desc = "Peek fold or hover" })
	end,
}
