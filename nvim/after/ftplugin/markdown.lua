require("declan.prose").setup()

-- conceallevel is deliberately NOT set here. markview.nvim drives it per-window
-- itself (3 while a preview mode is active, 0 otherwise) and pairs it with a
-- concealcursor derived from `preview.hybrid_modes`. Setting it by hand fought
-- that: the old value of 2 left conceal on in insert mode, where markview has
-- already torn its extmarks down, so raw markup showed with characters missing.
