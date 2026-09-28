# Neovim audit contract

The periodic auditor is read-only. It reports findings to the parent agent; it
never edits configuration or documentation itself.

## Required checks

1. Read `nvim/STYLE.md`, `nvim/README.md`, and `nvim/BINDINGS.md`.
2. Run `nvim/scripts/check-config` and `nvim/scripts/check-bindings`.
3. Confirm every Lua file parses and StyLua reports no drift.
4. Confirm Neovim starts headlessly and Lazy specs load without errors.
5. Inspect representative Lua, Markdown, Oil, Rust, and Haskell behavior when
   relevant to the current configuration.
6. Compare explicit global, buffer-local, LSP, language, and plugin-buffer maps
   with `BINDINGS.md`.
7. Check for accidental mapping collisions or undocumented shadowing.
8. Confirm every plugin pinned in `lazy-lock.json` is indexed in `README.md`.
9. Confirm files follow the directory ownership rules in `STYLE.md`.
10. Treat deliberately optional tools as warnings, but treat broken configured
    paths, syntax errors, startup errors, and stale documentation as failures.

## Output

Lead with actionable findings ordered by severity and include file references.
If there are no findings, say so briefly. End with exactly one of:

```text
NVIM_AUDIT: PASS
```

```text
NVIM_AUDIT: FAIL
```

Use `FAIL` whenever any required fix remains. A warning about an optional tool
does not by itself require `FAIL`.
