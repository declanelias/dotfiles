return {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    opts = {
        workspaces = {
            {
                name = "life",
                path = "~/.life",
            },
        },
        completion = {
            nvim_cmp = false,
            min_chars = 2,
        },
        ui = {
            enable = false, -- markview.nvim renders markdown; see lazy/markview.lua
        },
    },
}
