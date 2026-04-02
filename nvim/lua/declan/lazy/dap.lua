return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      {
        "mxsdev/nvim-dap-vscode-js",
        dependencies = {
          {
            "microsoft/vscode-js-debug",
            version = "v1.97.*",
            build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
          },
        },
      },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("dap-vscode-js").setup({
        debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
        adapters = { "pwa-node" },
      })

      dapui.setup()

      require("dap.ext.vscode").type_to_filetypes = {
        ["pwa-node"] = { "javascript", "typescript" },
      }

      -- Open UI + start
      vim.keymap.set("n", "<leader>dd", function()
        dapui.open()
        dap.continue()
      end, { desc = "Debug: Open UI + Continue" })

      vim.keymap.set("n", "<leader>d<space>", dap.continue, { desc = "Debug: Continue" })
      vim.keymap.set("n", "<leader>dl", ":DapStepInto<CR>", { desc = "Debug: Step Into" })
      vim.keymap.set("n", "<leader>dj", ":DapStepOver<CR>", { desc = "Debug: Step Over" })
      vim.keymap.set("n", "<leader>dh", ":DapStepOut<CR>", { desc = "Debug: Step Out" })
      vim.keymap.set("n", "<F1>", ":DapStepOut<CR>")
      vim.keymap.set("n", "<F2>", ":DapStepOver<CR>")
      vim.keymap.set("n", "<F3>", ":DapStepInto<CR>")
      vim.keymap.set("n", "<leader>d-", function() dap.restart() end, { desc = "Debug: Restart" })
      vim.keymap.set("n", "<leader>d_", function()
        dap.terminate()
        dapui.close()
        vim.opt.number = true
        vim.opt.relativenumber = true
      end, { desc = "Debug: Terminate" })
      vim.keymap.set("n", "<leader>du", function()
        dapui.toggle()
        vim.opt.number = true
        vim.opt.relativenumber = true
      end, { desc = "Debug: Toggle UI" })
      vim.keymap.set("n", "<leader>dgt", function()
        dap.set_log_level("TRACE")
      end, { desc = "Debug: Set TRACE log level" })
      vim.keymap.set("n", "<leader>dge", function()
        vim.cmd(":edit " .. vim.fn.stdpath("cache") .. "/dap.log")
      end, { desc = "Debug: Open log" })

      -- Auto open/close dapui
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },

  {
    "Weissle/persistent-breakpoints.nvim",
    config = function()
      require("persistent-breakpoints").setup({
        load_breakpoints_event = { "BufReadPost" },
      })
      vim.keymap.set("n", "<leader>db", ":PBToggleBreakpoint<CR>", { desc = "Debug: Toggle Breakpoint" })
    end,
  },
}
