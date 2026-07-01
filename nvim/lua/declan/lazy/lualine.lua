return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
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
        -- winbar is owned by dropbar.nvim now (see lazy/dropbar.lua), not lualine
    },
}
