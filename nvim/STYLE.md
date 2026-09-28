# Neovim configuration style

This file is the source of truth for the layout and coding conventions in this
directory. Agent-specific instruction files should point here instead of
copying these rules.

## Directory ownership

- `init.lua` only loads the root `declan` module.
- `lua/declan/init.lua` orders the core module imports.
- `lua/declan/set.lua` owns global editor options.
- `lua/declan/remap.lua` owns non-plugin global mappings and the leader key.
- `lua/declan/<feature>.lua` contains reusable local behavior that is not a
  plugin spec.
- `lua/declan/lazy/<feature>.lua` contains one primary plugin or one tightly
  coupled plugin family.
- `after/plugin/` contains setup that intentionally runs after plugins or the
  runtime are available. It must not contain Lazy specs.
- `after/ftplugin/` contains buffer-local filetype behavior.
- `scripts/` contains deterministic validation and agent-maintenance tools.
- `undo/` contains generated persistent-undo data and is never configuration.

## Lua and Lazy specs

- Format Lua with the repository's `.stylua.toml`.
- Prefer `opts` when Lazy can pass a declarative table to a plugin's `setup`.
- Use `config` for imperative setup, autocmds, mappings, or coordination among
  multiple plugins.
- Declare dependencies beside the plugin that owns them.
- Lazy-load with `keys`, `event`, `cmd`, or `ft` when doing so preserves the
  required behavior.
- Add a short rationale for deliberately eager plugins and unusual workarounds.
- Keep Rust LSP ownership in `rustaceanvim`, Haskell LSP ownership in
  `haskell-tools`, and shared servers in `after/plugin/lsp.lua`.
- Prefer local helper functions over repeated setup logic, but keep helpers
  close to their only caller.

## Mappings

- Use `vim.keymap.set` and give every nontrivial mapping a `desc`.
- Make modes explicit and no broader than required.
- Make mappings buffer-local when their behavior depends on an LSP, filetype,
  Git repository, or plugin buffer.
- Document intentional overrides and name the displaced default when useful.
- Update `BINDINGS.md` in the same logical change whenever a mapping's key,
  modes, scope, or behavior changes.

## Documentation

- Keep `README.md` aligned with plugin specs, the lockfile, language tooling,
  and important runtime behavior.
- Keep `BINDINGS.md` aligned with explicit mappings and the plugin defaults
  that this configuration deliberately enables.
- A `lazy-lock.json` change requires a full bindings audit because a plugin
  update may change default mappings without changing local Lua.

## Verification

Run these before finishing a Neovim configuration change:

```sh
nvim/scripts/check-config
nvim/scripts/check-bindings
```

Do not silently format or rewrite files from a lifecycle hook. Formatting is an
explicit implementation action; hooks only check it.
