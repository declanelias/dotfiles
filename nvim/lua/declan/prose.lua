-- Buffer settings shared by prose filetypes (markdown, text).
--
-- Lives here rather than in set.lua because these are per-buffer: hard-wrapping
-- code at 80 would be obnoxious. Called from after/ftplugin/ so it runs AFTER
-- $VIMRUNTIME/ftplugin/markdown.vim and wins over it.
local M = {}

function M.setup()
	-- THE fix for "my long lines never break in the file". The runtime markdown
	-- ftplugin already sets formatoptions+=t (auto-wrap as you type), but
	-- textwidth defaults to 0, which makes `t` a silent no-op. Setting a width is
	-- what actually inserts newlines, so j/k/0/$/A all behave normally again.
	vim.opt_local.textwidth = 80

	-- t = auto-wrap text at textwidth
	-- n = recognize numbered/bulleted lists when wrapping, so continuation lines
	--     indent under the text instead of under the marker (uses the runtime's
	--     formatlistpat). `text` files get neither of these by default.
	vim.opt_local.formatoptions:append("tn")

	-- The runtime ftplugin sets `l`, which means "don't auto-format a line that
	-- was ALREADY longer than textwidth when insert started". That would leave
	-- every pre-existing long paragraph unwrapped forever, which is exactly the
	-- files this is meant to fix. Drop it so editing an old line rewraps it.
	vim.opt_local.formatoptions:remove("l")

	-- listchars eol:. is useful in code, pure static in a paragraph
	vim.opt_local.list = false
end

return M
