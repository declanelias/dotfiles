return {
    "stevearc/oil.nvim",
    lazy = false,
    opts = {
        default_file_explorer = true,
        view_options = {
            show_hidden = true,
        },
    },
    keys = {
        { "<leader>pv", "<cmd>Oil<cr>", desc = "Open file explorer" },
    },
}
