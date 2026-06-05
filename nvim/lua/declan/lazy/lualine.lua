return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "SmiteshP/nvim-navic",
    },
    opts = {
        options = {
            theme = "nord",
        },
        sections = {
            lualine_c = {
                { "filename", path = 1 },
            },
        },
        winbar = {
            lualine_c = {
                { "navic" },
            },
        },
    },
}
