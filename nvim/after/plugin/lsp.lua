-- mason itself is set up by its lazy spec (lua/declan/lazy/mason.lua)
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "ts_ls",
    "pyright",
    "clangd",
  },
})

-- Lua
vim.lsp.config.lua_ls = {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
}

-- TypeScript/JavaScript
vim.lsp.config.ts_ls = {}

-- Python
vim.lsp.config.pyright = {}

-- C/C++
vim.lsp.config.clangd = {}

-- Rust: managed by rustaceanvim, not configured here

-- Advertise foldingRange support to every server (consumed by nvim-ufo's lsp provider).
-- Deep-merges with blink.cmp's capabilities rather than replacing them.
vim.lsp.config("*", {
  capabilities = {
    textDocument = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  },
})

-- Enable the servers
vim.lsp.enable({ "lua_ls", "ts_ls", "pyright", "clangd" })

-- Delete nvim's default gr-prefixed LSP maps (grr/grn/gra/gri/grt) so the
-- buffer-local `gr` below fires without waiting out the chord timeout
for _, lhs in ipairs({ "grr", "grn", "gra", "gri", "grt" }) do
  pcall(vim.keymap.del, "n", lhs)
end
pcall(vim.keymap.del, "x", "gra")

-- Keybindings when LSP attaches
-- (K — peek fold, else hover — is global, set in lazy/ufo.lua)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)          -- go to definition
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)      -- go to implementation (concrete body)
    vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)     -- go to type definition
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)          -- find all references
    vim.keymap.set("n", "<leader>li", vim.lsp.buf.incoming_calls, opts) -- call hierarchy: who calls this
    vim.keymap.set("n", "<leader>lo", vim.lsp.buf.outgoing_calls, opts) -- call hierarchy: what this calls
    vim.keymap.set("n", "[d", function()                             -- jump to previous error/warning
      vim.diagnostic.jump({ count = -1, float = true })
    end, opts)
    vim.keymap.set("n", "]d", function()                             -- jump to next error/warning
      vim.diagnostic.jump({ count = 1, float = true })
    end, opts)
    vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, opts)      -- rename symbol across project
    vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, opts) -- code actions (fixes, refactors)
    vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, opts) -- diagnostic float
    vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })            -- show inline type hints (like vscode)
  end,
})

vim.diagnostic.config({
  virtual_text = true, -- show error/warning text inline at end of line
  signs = true,       -- show icons in the sign column
  underline = true,   -- underline the problematic code
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight') then
      local group = vim.api.nvim_create_augroup('lsp-highlight-' .. args.buf, { clear = true })
      vim.api.nvim_create_autocmd('CursorHold', {
        buffer = args.buf,
        group = group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd('CursorMoved', {
        buffer = args.buf,
        group = group,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})
