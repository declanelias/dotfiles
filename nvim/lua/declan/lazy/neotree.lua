return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    close_if_last_window = true,
    filesystem = {
      hijack_netrw_behavior = "open_current",
      follow_current_file = { enabled = true, leave_dirs_open = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    window = {
      position = "left",
      width = 35,
    },
  },
  keys = {
    { "<leader>e", "<cmd>Neotree toggle reveal<cr>", desc = "Explorer tree (Neo-tree)" },
  },
}
