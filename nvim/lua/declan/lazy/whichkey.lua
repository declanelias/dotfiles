return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        spec = {
            { "<leader>d", group = "Debug" },
            { "<leader>dg", group = "Debug logs" },
            { "<leader>f", group = "Find" },
            { "<leader>h", group = "Git hunks" },
            { "<leader>l", group = "LSP" },
            { "<leader>lh", group = "Haskell" },
            { "<leader>w", group = "Window" },
        },
    },
}
