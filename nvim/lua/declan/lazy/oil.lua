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
    },
    keys = {
        -- both open oil in a floating window at the current file's directory
        { "-", function() require("oil").open_float() end, desc = "Open parent dir (oil)" },
        { "<leader>e", function() require("oil").open_float() end, desc = "File explorer (oil)" },
    },
}
