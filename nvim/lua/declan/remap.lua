vim.g.mapleader = " "
-- <leader>e is mapped in oil.lua's plugin spec

vim.keymap.set("n", "H", "<C-o>", { desc = "Jump backward" })
vim.keymap.set("n", "L", "<C-i>", { desc = "Jump forward" })

-- Convenient aliases for Vim's native <C-w> window commands. Unlock-first
-- Zellij also lets the original Control chords reach Neovim.
vim.keymap.set("n", "<leader>wh", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<leader>wj", "<C-w>j", { desc = "Window down" })
vim.keymap.set("n", "<leader>wk", "<C-w>k", { desc = "Window up" })
vim.keymap.set("n", "<leader>wl", "<C-w>l", { desc = "Window right" })
vim.keymap.set("n", "<leader>ws", "<C-w>s", { desc = "Split below" })
vim.keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Split right" })
vim.keymap.set("n", "<leader>wq", "<C-w>q", { desc = "Close window" })
vim.keymap.set("n", "<leader>wo", "<C-w>o", { desc = "Close other windows" })
