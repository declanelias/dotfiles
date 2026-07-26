-- Buffer-based file manager: a directory opens as an editable buffer. Rename a
-- line to rename a file, dd to delete, p to move, add a line to create; :w applies.
-- Replaces neo-tree. https://github.com/stevearc/oil.nvim
return {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false, -- load at startup so it can hijack netrw
    opts = {
        default_file_explorer = true, -- take over netrw (as neo-tree did)
        view_options = {
            show_hidden = true, -- neo-tree showed dotfiles; keep them visible
        },
        keymaps = {
            -- zellij (clear-defaults) swallows <C-s>/<C-h>/<C-t>/<C-p> before nvim
            -- sees them, so oil's split/tab/preview opens are unreachable. Mirror
            -- them onto the g-prefix oil already uses for gx/gs/g./g?
            ["gv"] = { "actions.select", opts = { vertical = true }, desc = "Open in vsplit" },
            ["gh"] = { "actions.select", opts = { horizontal = true }, desc = "Open in split" },
            ["gt"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },
            ["gp"] = { "actions.preview", desc = "Preview" },
            ["q"] = { "actions.close", mode = "n" },
        },
    },
    keys = {
        -- in-window, NOT a float: oil takes over the current buffer and close()
        -- puts the old one back, so splits/jumps/<leader>w all behave normally
        { "-", function() require("oil").open() end, desc = "Open parent dir (oil)" },
        {
            "<leader>e",
            function()
                local oil = require("oil")
                if vim.bo.filetype == "oil" then
                    oil.close()
                else
                    oil.open()
                end
            end,
            desc = "File explorer (oil)",
        },
    },
}
