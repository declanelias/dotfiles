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
			return ufo
				.getFolds(bufnr, "lsp")
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

		-- Loading on BufReadPost can happen after UFO's own BufWinEnter hook for
		-- the first file. Attach that startup buffer once setup has completed;
		-- later buffers are handled by UFO's normal autocmd path.
		local initial_bufnr = vim.api.nvim_get_current_buf()
		vim.schedule(function()
			if
				vim.api.nvim_buf_is_valid(initial_bufnr)
				and vim.api.nvim_buf_is_loaded(initial_bufnr)
				and not ufo.hasAttached(initial_bufnr)
			then
				ufo.attach(initial_bufnr)
			end
		end)

		-- UFO keeps foldlevel pinned at 99, so track the intended display level
		-- per window while its APIs open and close the underlying manual folds.
		local function max_level()
			local level = 0
			for lnum = 1, vim.fn.line("$") do
				level = math.max(level, vim.fn.foldlevel(lnum))
			end
			return level
		end

		local function current_level(maximum)
			return math.min(vim.w.ufo_foldlevel or maximum, maximum)
		end

		local function prepare_level_folds()
			local bufnr = vim.api.nvim_get_current_buf()
			if not ufo.hasAttached(bufnr) then
				ufo.attach(bufnr)
			end

			local ranges
			for _, provider in ipairs({ "treesitter", "indent" }) do
				local ok, candidate = pcall(ufo.getFolds, bufnr, provider)
				if ok and type(candidate) == "table" and #candidate > 0 then
					ranges = candidate
					break
				end
			end
			if ranges then
				ufo.openAllFolds()
				ufo.applyFolds(bufnr, ranges)
			end

			local maximum = max_level()
			vim.w.ufo_foldlevel = maximum
			return maximum
		end

		local function level_maximum()
			if vim.w.ufo_foldlevel == nil then
				return prepare_level_folds()
			end
			return max_level()
		end

		vim.keymap.set("n", "zR", function()
			ufo.openAllFolds()
			vim.w.ufo_foldlevel = max_level()
		end, { desc = "Fold: open all" })
		vim.keymap.set("n", "zM", function()
			level_maximum()
			ufo.closeAllFolds()
			vim.w.ufo_foldlevel = 0
		end, { desc = "Fold: close all" })
		vim.keymap.set("n", "zm", function()
			local maximum = level_maximum()
			if maximum == 0 then
				vim.notify("No fold levels are available in this buffer", vim.log.levels.INFO)
				return
			end
			local level = math.max(current_level(maximum) - vim.v.count1, 0)
			ufo.closeFoldsWith(level)
			vim.w.ufo_foldlevel = level
		end, { desc = "Fold: close more levels" })
		vim.keymap.set("n", "zr", function()
			local maximum = level_maximum()
			if maximum == 0 then
				vim.notify("No fold levels are available in this buffer", vim.log.levels.INFO)
				return
			end
			local level = math.min(current_level(maximum) + vim.v.count1, maximum)
			if level >= maximum then
				ufo.openAllFolds()
			else
				ufo.closeFoldsWith(level)
			end
			vim.w.ufo_foldlevel = level
		end, { desc = "Fold: open more levels" })

		-- Return semantic ranges from the same textobjects queries that power
		-- af/if and ac/ic. Unlike numeric fold levels, these distinguish functions
		-- from the impl/class/trait containers surrounding them.
		local function textobject_ranges(bufnr, capture)
			local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
			if not ok or not parser then
				return {}
			end

			parser:parse(true)
			local ranges = {}
			local seen = {}
			parser:for_each_tree(function(tree, language_tree)
				local query = vim.treesitter.query.get(language_tree:lang(), "textobjects")
				if not query then
					return
				end

				local root = tree:root()
				local start_row, _, end_row = root:range()
				for id, node in query:iter_captures(root, bufnr, start_row, end_row + 1) do
					if query.captures[id] == capture then
						local srow, scol, erow, ecol = node:range()
						local end_line = erow + (ecol > 0 and 1 or 0)
						local key = table.concat({ srow, scol, erow, ecol }, ":")
						if end_line > srow + 1 and not seen[key] then
							seen[key] = true
							table.insert(ranges, {
								start_row = srow,
								start_col = scol,
								end_row = erow,
								end_col = ecol,
								start_line = srow + 1,
								end_line = end_line,
							})
						end
					end
				end
			end)

			-- Close nested functions before their parents. If an outer function is
			-- closed first, native foldclose cannot reach its already-hidden child.
			table.sort(ranges, function(a, b)
				local a_span = a.end_line - a.start_line
				local b_span = b.end_line - b.start_line
				if a_span == b_span then
					return a.start_line > b.start_line
				end
				return a_span < b_span
			end)
			return ranges
		end

		local function contains_line(range, line)
			return line >= range.start_line and line <= range.end_line
		end

		local function function_ranges_for_scope(bufnr, current_container_only)
			local all_ranges = textobject_ranges(bufnr, "function.outer")
			if #all_ranges == 0 then
				vim.notify("No Treesitter function textobjects in this buffer", vim.log.levels.INFO)
				return
			end
			if not current_container_only then
				return all_ranges, all_ranges
			end

			local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
			local container
			for _, candidate in ipairs(textobject_ranges(bufnr, "class.outer")) do
				if contains_line(candidate, cursor_line) then
					if not container or candidate.end_line - candidate.start_line < container.end_line - container.start_line then
						container = candidate
					end
				end
			end
			if not container then
				vim.notify("Cursor is not inside an impl/class/trait", vim.log.levels.INFO)
				return
			end

			local ranges = vim.tbl_filter(function(range)
				return range.start_line >= container.start_line and range.end_line <= container.end_line
			end, all_ranges)
			if #ranges == 0 then
				vim.notify("No function textobjects in the current impl/class/trait", vim.log.levels.INFO)
				return
			end
			return all_ranges, ranges
		end

		local function apply_function_outline(current_container_only)
			local bufnr = vim.api.nvim_get_current_buf()
			local all_ranges, ranges = function_ranges_for_scope(bufnr, current_container_only)
			if not all_ranges then
				return
			end

			local view = vim.fn.winsaveview()
			local cursor = vim.api.nvim_win_get_cursor(0)
			local current
			for _, range in ipairs(ranges) do
				if contains_line(range, cursor[1]) then
					if not current or range.end_line - range.start_line < current.end_line - current.start_line then
						current = range
					end
				end
			end

			-- Whole-file outlining starts from an open canvas. The container-scoped
			-- action preserves fold state everywhere outside the selected container.
			if not ufo.hasAttached(bufnr) then
				ufo.attach(bufnr)
			end
			if not current_container_only then
				ufo.openAllFolds()
			end
			local preserved_closed = {}
			if current_container_only then
				local selected = {}
				for _, range in ipairs(ranges) do
					selected[range.start_line .. ":" .. range.end_line] = true
				end
				for _, range in ipairs(all_ranges) do
					local key = range.start_line .. ":" .. range.end_line
					if not selected[key] and vim.fn.foldclosed(range.start_line) ~= -1 then
						table.insert(preserved_closed, range)
					end
				end
			end
			local fold_ranges = {}
			for _, range in ipairs(all_ranges) do
				table.insert(fold_ranges, {
					startLine = range.start_row,
					endLine = range.end_line - 1,
				})
			end
			if ufo.applyFolds(bufnr, fold_ranges) == -1 then
				vim.notify("Could not apply function folds in this window", vim.log.levels.INFO)
				vim.fn.winrestview(view)
				return
			end

			local closed = 0
			for _, range in ipairs(ranges) do
				vim.cmd(("silent! %dfoldclose"):format(range.start_line))
				if vim.fn.foldclosed(range.start_line) ~= -1 then
					closed = closed + 1
				end
			end
			for _, range in ipairs(preserved_closed) do
				vim.cmd(("silent! %dfoldclose"):format(range.start_line))
			end

			if closed == 0 then
				vim.notify("No function folds are available yet", vim.log.levels.INFO)
				vim.fn.winrestview(view)
				return
			end
			vim.w.ufo_foldlevel = nil

			view.lnum = current and current.start_line or cursor[1]
			view.col = current and current.start_col or cursor[2]
			view.topline = math.min(view.topline, view.lnum)
			vim.fn.winrestview(view)
		end

		local function open_function_outline(current_container_only)
			local bufnr = vim.api.nvim_get_current_buf()
			local all_ranges, ranges = function_ranges_for_scope(bufnr, current_container_only)
			if not all_ranges then
				return
			end

			local view = vim.fn.winsaveview()
			for _, range in ipairs(ranges) do
				-- Open every fold containing the function's first line. This reveals
				-- the function even if an enclosing container is currently folded.
				for _ = 1, #all_ranges + 1 do
					if vim.fn.foldclosed(range.start_line) == -1 then
						break
					end
					vim.cmd(("silent! %dfoldopen"):format(range.start_line))
				end
			end
			vim.w.ufo_foldlevel = nil
			vim.fn.winrestview(view)
		end

		vim.keymap.set("n", "zf", function()
			apply_function_outline(false)
		end, { desc = "Folds: file function outline" })
		vim.keymap.set("n", "zF", function()
			open_function_outline(false)
		end, { desc = "Folds: open file functions" })
		vim.keymap.set("n", "zq", function()
			apply_function_outline(true)
		end, { desc = "Folds: current container outline" })
		vim.keymap.set("n", "zQ", function()
			open_function_outline(true)
		end, { desc = "Folds: open current container functions" })
		vim.keymap.set("n", "zK", ufo.peekFoldedLinesUnderCursor, { desc = "Fold: peek" })
	end,
}
