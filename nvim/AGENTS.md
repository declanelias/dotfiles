# Neovim agent guide

This directory is the deeply indexed part of the dotfiles repository. Use the
documents here as routers, then verify claims against the current Lua and
installed plugins.

## Required reading

1. Always read `STYLE.md` before changing configuration.
2. Read `README.md` for architecture, plugins, language tooling, or startup
   behavior.
3. Read `BINDINGS.md` for mappings, plugin key presets, completion, or terminal
   key interactions.
4. Read `AUDIT.md` only for periodic audits or guard maintenance.
5. Inspect the owning Lua before relying on any documentation claim.

## Task routing

| Task | Primary source |
| --- | --- |
| Global options | `lua/declan/set.lua` |
| Global non-plugin mappings | `lua/declan/remap.lua` |
| Plugin behavior | Matching file under `lua/declan/lazy/` |
| Shared LSP and diagnostics | `after/plugin/lsp.lua` |
| Rust tooling | `lua/declan/lazy/rustaceanvim.lua` |
| Haskell tooling | `lua/declan/lazy/haskell-tools.lua` |
| Treesitter | `lua/declan/lazy/treesitter.lua` and `after/plugin/treesitter.lua` |
| Colors and highlights | `lua/declan/lazy/colorscheme.lua` and `after/plugin/colors.lua` |
| Markdown/text behavior | `lua/declan/prose.lua` and `after/ftplugin/` |
| Plugin inventory | `lazy-lock.json` and `README.md` |
| Binding inventory | Owning mapping source and `BINDINGS.md` |
| Agent automation | `scripts/agent_guard.py`, `../.codex/`, and `../.claude/` |

## Invariants

- Rustaceanvim owns `rust-analyzer`; shared LSP setup must not start it.
- Haskell-tools owns HLS; shared LSP setup must not start it.
- Markview is intentionally disabled unless both its spec and documentation say
  otherwise.
- Oil replaces netrw, hides `.git`, and shows Git-ignored entries.
- UFO's provider order is LSP, then Treesitter, then indentation.
- Markdown buffer-local runtime mappings intentionally override some global
  Treesitter class/type mappings.
- Plugin-default mappings are part of `BINDINGS.md`; a `lazy-lock.json` change
  therefore requires a full audit.

## Completion requirements

- Preserve the directory ownership and Lua conventions in `STYLE.md`.
- Run `scripts/check-config` and `scripts/check-bindings` after configuration
  changes.
- Review `BINDINGS.md` every time. Update it in the same turn when a key, mode,
  scope, description, or behavior changed.
- Update `README.md` when plugin or tooling behavior changed.
- When the lifecycle guard says an audit is due, invoke the platform's
  configured Neovim auditor (`nvim_auditor` in Codex or `nvim-auditor` in
  Claude), wait for it, fix all findings, and rerun it until it ends with
  `NVIM_AUDIT: PASS`.
- Never edit `undo/`.
