vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.list = true
vim.opt.listchars = "eol:.,tab:>-,trail:~,extends:>,precedes:<"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes:1"
vim.opt.scrolloff = 8
vim.opt.showcmd = true

vim.opt.wrap = true
vim.opt.linebreak = true -- wrap at word boundaries, not mid-word

vim.opt.swapfile = true -- recover unsaved work after a crash
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.config/nvim/undo"
vim.opt.undofile = true
vim.opt.clipboard = "unnamed"

vim.opt.updatetime = 250

vim.opt.ignorecase = true -- case-insensitive search...
vim.opt.smartcase = true -- ...unless the pattern has an uppercase letter
