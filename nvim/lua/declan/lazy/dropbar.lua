-- IDE-like breadcrumb winbar (file path > symbol path) at the top of each window.
-- Replaces nvim-navic. LSP source with a treesitter fallback, so it still shows
-- context in buffers with no LSP. https://github.com/Bekaboo/dropbar.nvim (nvim >= 0.11)
return {
    "Bekaboo/dropbar.nvim",
    dependencies = {
        -- optional: fuzzy-find inside the dropbar drop-down menu
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    opts = {},
    config = function(_, opts)
        require("dropbar").setup(opts)
        local api = require("dropbar.api")
        -- jump to a breadcrumb component by keyboard (VS Code-ish nav)
        vim.keymap.set("n", "<leader>;", api.pick, { desc = "dropbar: pick symbol" })
    end,
}
