return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        current_line_blame = true,
        current_line_blame_opts = {
            delay = 0,
        },
        on_attach = function(bufnr)
            local gs = require("gitsigns")
            local function map(mode, l, r, desc)
                vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
            end
            map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
            map("n", "[h", function() gs.nav_hunk("prev") end, "Prev hunk")
            map("n", "<leader>hs", gs.stage_hunk, "Stage/unstage hunk")
            map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
            map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selection")
            map("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset selection")
            map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
            map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line (full)")
            map("n", "<leader>hd", gs.diffthis, "Diff against index")
        end,
    },
}
