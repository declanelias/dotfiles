# Terminal reading tools

Chezmoi manages the Apple Silicon macOS binaries in
`home/dot_local/bin/`: `tdf` 0.5.0 and Leaf 1.29.3 (the Markdown viewer).
These are snapshots of the working MacBook binaries from November 16, 2026,
so both machines use the same builds. They are not portable to Intel or Linux.

The `tdf` binary was built from https://github.com/itsjunetime/tdf at
`de00504`, with the local saved-page changes preserved in `tdf-position.patch`.
The patch applies to that upstream revision; rebuilding requires its Cargo
project and toolchain. Reading positions remain machine-local in
`~/.local/state/tdf` (or `$XDG_STATE_HOME/tdf`).

Leaf renders Markdown; the Homebrew formula named `leaf` is a different tool.
`~/.local/bin` must precede `/opt/homebrew/bin` on PATH, as configured in
`.zsh/exports.zsh`. Neither reader currently has a custom configuration file.

## Deploy

After committing and pushing, on the other Mac:

```sh
cd ~/dotfiles
git pull --ff-only
chezmoi apply --exclude scripts ~/.local/bin/tdf ~/.local/bin/leaf ~/.config/nvim
```

Restart Neovim after pulling. Its `declan.pdf` module opens local PDFs with
`tdf`: a right-hand Rex split inside Rex, or a terminal tab elsewhere.
The existing `rex` CLI is needed for the Rex split.

To refresh either binary, install and verify the intended build, then run
`chezmoi add --follow --recursive=false ~/.local/bin/tdf ~/.local/bin/leaf` and commit the
changed files. Update provenance and hashes here too.

## Binary SHA-256

- `tdf`: `5d6252f7a02a0687413cfc8e171204c240c4f3eab64ad49c65cc9720eabd5f1a`
- `leaf`: `6df7dfa70a97315cff02b20cbec3edd4f40ea2188d02ee02948212bff52ae1af`
