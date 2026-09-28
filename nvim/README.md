# Neovim configuration

This directory is the source for `~/.config/nvim`. The repository installer
symlinks it into place, `init.lua` loads the `declan` modules, and
[`lazy.nvim`](https://github.com/folke/lazy.nvim) discovers every plugin spec in
`lua/declan/lazy/`.

For the keyboard-oriented view of this setup, see [BINDINGS.md](BINDINGS.md).

## Startup and layout

```text
init.lua
└── lua/declan/init.lua
    ├── remap.lua       leader and global mappings
    ├── set.lua         editor options
    └── lazy_init.lua   lazy.nvim bootstrap and plugin discovery

lua/declan/lazy/        one plugin spec (or plugin family) per file
after/plugin/           shared LSP, Treesitter, color, and worklog setup
after/ftplugin/         Markdown/text prose settings
scripts/                deterministic config, bindings, and agent-hook checks
lazy-lock.json          exact installed plugin revisions
undo/                   persistent undo data; not configuration
```

The editor uses Space as `<leader>`, two-space indentation, absolute and
relative line numbers, smart-case search, word-boundary wrapping, a permanent
sign column, the unnamed clipboard, and persistent undo under
`~/.config/nvim/undo`.

Markdown and plain-text buffers additionally hard-wrap at 80 columns, preserve
list indentation while wrapping, and hide `listchars`.

## Plugin index

The table includes every plugin pinned in `lazy-lock.json`, including support
libraries and debugger adapters. “Configured by” points to the owning spec;
dependencies inherit that spec's load path unless noted otherwise.

| Plugin | What it does here | Configured by |
| --- | --- | --- |
| `lazy.nvim` | Bootstraps and manages the plugin graph; scans `declan.lazy` and suppresses change-detection notifications. | `lua/declan/lazy_init.lua` |
| `nvim-treesitter` | Installs parsers, starts syntax highlighting, and supplies syntax-aware indentation for configured filetypes. | `lazy/treesitter.lua`, `after/plugin/treesitter.lua` |
| `nvim-treesitter-textobjects` | Adds function/class/argument text objects and structural movement. | `lazy/treesitter.lua` |
| `blink.cmp` | Completion from LSP, paths, snippets, and the current buffer; automatically shows documentation and uses its `default` key preset. | `lazy/blink.lua` |
| `friendly-snippets` | Supplies language templates to Blink's native snippet source, including Rust functions and trait implementations. | `lazy/blink.lua` |
| `nvim-autopairs` | Inserts paired delimiters while typing, skips existing closing delimiters, and handles Enter/Backspace inside empty pairs; loads on InsertEnter. | `lazy/autopairs.lua` |
| `nvim-surround` | Adds, changes, and deletes paired delimiters, tags, and function-call surrounds. | `lazy/surround.lua` |
| `nvim-ufo` | Provides folding with an LSP → Treesitter → indent fallback, fold-count virtual text, semantic file/container outline actions, and fold peeking. | `lazy/ufo.lua` |
| `promise-async` | Promise implementation used by UFO's asynchronous provider fallback. | `lazy/ufo.lua` |
| `telescope.nvim` | Finds files, Git files, buffers, and text; ignores `.git`, `node_modules`, `dist`, and `target`. | `lazy/telescope.lua` |
| `telescope-fzf-native.nvim` | Compiled FZF sorter used by Telescope and optional fuzzy matching in Dropbar menus. | `lazy/telescope.lua`, `lazy/dropbar.lua` |
| `plenary.nvim` | Shared Lua utility library for Telescope, Harpoon, and Obsidian. | dependency |
| `harpoon` (`harpoon2`) | Maintains a short working set of files with a quick menu and direct slots 1–4. | `lazy/harpoon.lua` |
| `oil.nvim` | Replaces netrw with an editable directory buffer; operations are applied with `:write`, deletion goes to trash, and hidden files are shown. | `lazy/oil.lua` |
| `oil-git.nvim` | Adds Git status decorations to Oil, including directory highlights. | `lazy/oil.lua` |
| `oil-lsp-diagnostics.nvim` | Shows aggregated LSP diagnostics beside files/directories in Oil. | `lazy/oil.lua` |
| `nvim-web-devicons` | Supplies file/language icons to Oil, Lualine, and the currently disabled Markview setup. | dependency |
| `dropbar.nvim` | Renders a file-and-symbol breadcrumb winbar using LSP with Treesitter fallback; the breadcrumb is keyboard-pickable. | `lazy/dropbar.lua` |
| `trouble.nvim` | Presents diagnostics, quickfix entries, and location-list entries in a navigable problem view. | `lazy/trouble.lua` |
| `mason.nvim` | Installs and manages editor tooling in Neovim. | `lazy/mason.lua` |
| `mason-lspconfig.nvim` | Bridges Mason packages to Neovim LSP and ensures the shared servers below are installed. | `lazy/mason.lua`, `after/plugin/lsp.lua` |
| `nvim-lspconfig` | Supplies server definitions used by Neovim's native `vim.lsp.config`/`vim.lsp.enable` APIs. | `lazy/mason.lua`, `after/plugin/lsp.lua` |
| `rustaceanvim` | Owns `rust-analyzer`, Rust diagnostics, error explanations, and Rust-specific inlay-hint controls. | `lazy/rustaceanvim.lua` |
| `haskell-tools.nvim` | Owns HLS and adds Hoogle, evaluation, project-file, and GHCi tools. | `lazy/haskell-tools.lua` |
| `conform.nvim` | Formats supported filetypes on save, preferring configured CLI formatters and falling back to LSP formatting. | `lazy/conform.lua` |
| `nvim-lint` | Runs Vale for Markdown and text after reads/writes and when leaving Insert mode; the plugin is skipped if `vale` is unavailable. | `lazy/lint.lua` |
| `gitsigns.nvim` | Shows Git hunks, immediate current-line blame, hunk navigation/staging/reset/preview, and index diffs. | `lazy/gitsigns.lua` |
| `zenbones.nvim` | Provides the published grayscale Zenwritten variant over the matching terminal background. | `lazy/colorscheme.lua`, `after/plugin/colors.lua` |
| `lush.nvim` | Supplies the color-generation engine used by Zenbones and Zenwritten. | dependency |
| `lualine.nvim` | Renders the published Zenwritten statusline and shows the filename relative to the working directory. | `lazy/lualine.lua` |
| `markview.nvim` | Prepared Markdown renderer with numbered, uncolored headings and raw markup in Insert mode. It is currently **disabled** with `enabled = false`. | `lazy/markview.lua` |
| `obsidian.nvim` | Adds wiki/Markdown link following, checkbox actions, and note commands to every Markdown file, treating the current file's directory as its workspace. Its UI renderer and `nvim-cmp` integration are disabled. | `lazy/obsidian.lua` |
| `nvim-dap` | Core Debug Adapter Protocol client and session control. | `lazy/dap.lua` |
| `nvim-dap-ui` | Supplies scopes, breakpoints, stacks, watches, REPL, and console panes; opens/closes with debug sessions. | `lazy/dap.lua` |
| `nvim-nio` | Async I/O dependency required by `nvim-dap-ui`. | `lazy/dap.lua` |
| `nvim-dap-python` | Registers debugpy adapters and default Python launch/pytest configurations. | `lazy/dap.lua` |
| `nvim-dap-vscode-js` | Connects `nvim-dap` to VS Code's JavaScript debugger through the `pwa-node` adapter. | `lazy/dap.lua` |
| `vscode-js-debug` | Built debugger implementation for JavaScript and TypeScript. | `lazy/dap.lua` |
| `persistent-breakpoints.nvim` | Persists breakpoints between sessions and reloads them when buffers are read. | `lazy/dap.lua` |

## Language tooling

### LSP servers

The shared LSP setup installs and enables these servers:

| Server | File/domain |
| --- | --- |
| `lua_ls` | Lua; configured to recognize the `vim` global |
| `ts_ls` | JavaScript and TypeScript |
| `pyright` | Python |
| `clangd` | C and C++ |
| `eslint` | Project JavaScript/TypeScript linting |
| `jsonls` | JSON and JSON-with-comments |
| `taplo` | TOML |
| `yamlls` | YAML |

Rust is intentionally owned by `rustaceanvim`, and Haskell by
`haskell-tools.nvim`; neither is started by the shared LSP file. Every attached
server receives Blink completion capabilities and folding-range capabilities
for UFO. LSP buffers get symbol navigation, references, call hierarchy,
diagnostics, rename/code actions, document highlighting, and enabled inlay
hints.

Diagnostics update while typing. Other lines receive compact virtual text,
while the cursor line receives the full message on virtual lines that wrap to
the current window width.
On Neovim 0.12.x, the shared LSP setup also drops stale, out-of-range inlay
hints before rendering to prevent an upstream redraw failure from hiding those
diagnostic messages.

### Formatting

Conform runs before save with a two-second timeout:

| Filetype | Formatter chain |
| --- | --- |
| Lua | `stylua` |
| Python | `black` |
| JavaScript, TypeScript, JSX/TSX, JSON/JSONC, YAML, Markdown/MDX | `prettierd`, then `prettier` |
| TOML | `taplo` |
| Shell | `shfmt` |
| Rust | `rustfmt` |
| C/C++ | `clang-format` |

Only the first available Prettier implementation runs. If no configured CLI
formatter is available, Conform asks the attached LSP to format.

### Treesitter

Parsers are installed for Bash, Haskell, JavaScript, JSON, Lua, Markdown,
Markdown inline syntax, Python, Rust, TOML, TSX, TypeScript, and YAML.
Highlighting and Treesitter indentation are enabled for the corresponding
filetypes, including `javascriptreact`, `typescriptreact`, `jsonc`, and `sh`.

## Other local behavior

- Rust snippets include `fn`, `pfn` (public function), and `impl-trait`. Select
  the snippet in Blink and accept with Ctrl-Y, then use Tab/Shift-Tab to move
  between placeholders. Blink uses Neovim's native snippet engine.
- `after/plugin/worklog.lua` is not a plugin. It records buffer activity,
  aggregate key/mode statistics, repeat runs, leader-map usage, and macro
  metadata as JSONL under `~/.local/share/worklog`. Insert- and command-line
  content is counted but never recorded.
- Oil always hides `.git` but shows Git-ignored entries, which oil-git marks as
  ignored.
- UFO is disabled for special buffers such as Oil. New buffers start fully
  unfolded. Its semantic outline closes `@function.outer` textobjects while
  leaving structural containers visible; paired actions reopen functions for
  the whole file or only the current `impl`/class/trait. UFO-backed `zm`/`zr`
  mappings synchronously initialize Treesitter/indent folds and then close/open
  relative nesting levels across the file.
- Zenwritten leaves `Normal` transparent over Ghostty's matching `#191919`
  background.

## External tools

`install.sh` installs Neovim, Node, `tree-sitter-cli`, and `shfmt`, then links
this directory to `~/.config/nvim`. Some configured features still depend on
tools being available from the project, system, or Mason:

- Search: `git` and `rg` (Telescope live grep).
- Telescope/Dropbar FZF build: `make` and a C compiler.
- JavaScript debugging: `node`/`npm`; the adapter is built by Lazy.
- Python debugging: Mason's `debugpy` package at
  `~/.local/share/nvim/mason/packages/debugpy/venv/bin/python`.
- Formatting: the formatter executables listed above.
- Prose linting: `vale` (optional; `nvim-lint` does not load without it).
- Language servers: installed automatically by Mason except
  `rust-analyzer`/HLS, which are managed outside the shared ensure list.

## Maintenance

- `:Lazy` opens the plugin manager; `:Lazy sync` installs, updates, and cleans
  plugins while refreshing `lazy-lock.json`.
- `:Mason` shows installed language tools.
- `:ConformInfo` explains which formatter a buffer will use.
- `:checkhealth` checks Neovim and plugin dependencies.
- `scripts/check-config` checks StyLua, Lua syntax, headless startup, bindings,
  and lockfile documentation.
- `scripts/check-bindings` runs only the configured-binding coverage check.
- `python3 scripts/agent_guard.py status` shows the private per-worktree edit
  counter and periodic-audit state.
- When adding or changing a mapping, update [BINDINGS.md](BINDINGS.md) beside
  the code that defines it.

## Agent safeguards

Codex and Claude Code share the deterministic guard in
`scripts/agent_guard.py`. Their repository-local lifecycle hooks take a content
baseline at the start of a prompt, detect net Neovim configuration changes,
and prevent the agent from finishing while fast checks or binding
documentation are stale.

A successful configuration-changing agent turn increments a counter stored
inside the worktree's private Git directory. On the tenth turn—or immediately
after `lazy-lock.json` changes—the guard requires the platform's configured
read-only Neovim auditor. A passing audit is tied to the exact configuration
fingerprint and resets the counter; another configuration change invalidates
that pass.

- Layout and Lua conventions: [STYLE.md](STYLE.md)
- Periodic review contract: [AUDIT.md](AUDIT.md)
- Canonical scoped instructions: `AGENTS.md` (`CLAUDE.md` points to it)
- Codex adapter: `../.codex/hooks.json` and
  `../.codex/agents/nvim-auditor.toml`
- Claude adapter: `../.claude/settings.json` and
  `../.claude/agents/nvim-auditor.md`

Both clients require the repository hooks to be trusted before they run. Use
their `/hooks` browser to inspect the exact commands first.
