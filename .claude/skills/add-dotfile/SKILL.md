---
name: add-dotfile
description: Add a new config file to the dotfiles repo with symlinks and optional brew package install
disable-model-invocation: true
argument-hint: <path-to-config>
allowed-tools: Read, Write, Edit, Bash, Glob
---

# Add Dotfile

Add the config at `$ARGUMENTS` to this dotfiles repo and wire it up.

## Steps

1. Read the config file at the provided path.
2. Create a matching directory in the dotfiles repo root (e.g. `~/.config/yabai/yabairc` -> `yabai/yabairc`). Do NOT nest under `.config/` in the repo.
3. Copy the config contents into the new repo file.
4. Update `install.sh`:
   - Add the new symlink target/source pair to the `targets` and `sources` arrays in `create_symlinks()`.
   - If the config requires a brew package, add it to the `packages` array in `install_brew_packages()`.
5. Ask the user if any brew packages need to be installed for this config. If yes, add them.

## Rules

- Keep config files at the repo root in their own folder (e.g. `yabai/`, `skhd/`), not under `.config/`.
- The `mkdir -p` in `create_symlinks()` handles creating parent dirs at the target location.
- Preserve the original file contents exactly.
