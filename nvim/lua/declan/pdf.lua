-- Open PDFs in tdf instead of reading their bytes into a buffer.
-- tdf draws pages with the terminal's image protocol, which Neovim's built-in
-- terminal cannot display, so inside Rex it gets a real pane beside the editor.
-- Elsewhere it falls back to a terminal tab with tdf's low-resolution output.
local M = {}

local function in_rex()
	return vim.env.REX_SESSION ~= nil and vim.env.REX_BLOCK ~= nil and vim.fn.executable("rex") == 1
end

local function open_in_rex_pane(tdf, path)
	local command = {
		"rex",
		"split",
		"--session",
		vim.env.REX_SESSION,
		"--block",
		vim.env.REX_BLOCK,
		"--split",
		"right",
		"--label",
		vim.fs.basename(path),
		"--shell",
		"none",
		"--",
		tdf,
		path,
	}
	vim.system(command, { text = true }, function(result)
		if result.code ~= 0 then
			vim.schedule(function()
				vim.notify("rex could not open tdf: " .. vim.trim(result.stderr), vim.log.levels.ERROR)
			end)
		end
	end)
end

local function open_in_terminal_tab(tdf, path)
	vim.cmd.tabnew()
	local buf = vim.api.nvim_get_current_buf()
	vim.fn.jobstart({ tdf, path }, {
		term = true,
		on_exit = function()
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_delete(buf, { force = true })
				end
			end)
		end,
	})
	vim.cmd.startinsert()
end

-- Return each window showing the PDF to the buffer it came from, then drop the
-- PDF buffer so no empty buffer named after the PDF is left behind.
local function discard(buf)
	for _, win in ipairs(vim.fn.win_findbuf(buf)) do
		vim.api.nvim_win_call(win, function()
			local alternate = vim.fn.bufnr("#")
			if alternate > 0 and alternate ~= buf and vim.api.nvim_buf_is_valid(alternate) then
				vim.api.nvim_win_set_buf(win, alternate)
			else
				vim.cmd.enew()
			end
		end)
	end
	vim.api.nvim_buf_delete(buf, { force = true })
end

function M.setup()
	-- Without tdf, PDFs keep Neovim's normal behavior.
	local tdf = vim.fn.exepath("tdf")
	if tdf == "" then
		return
	end
	vim.api.nvim_create_autocmd("BufReadCmd", {
		group = vim.api.nvim_create_augroup("DeclanPdf", {}),
		-- One case-insensitive pattern; separate *.pdf and *.PDF patterns would
		-- both match on case-insensitive file systems and open tdf twice.
		pattern = "*.[pP][dD][fF]",
		desc = "Open PDFs in tdf",
		callback = function(args)
			local path = vim.api.nvim_buf_get_name(args.buf)
			-- Leave remote (oil-ssh) and nonexistent paths to other handlers.
			if vim.fn.filereadable(path) == 0 then
				return
			end
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(args.buf) then
					discard(args.buf)
				end
				if in_rex() then
					open_in_rex_pane(tdf, path)
				else
					open_in_terminal_tab(tdf, path)
				end
			end)
		end,
	})
end

return M
