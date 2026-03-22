#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

install_homebrew() {
  if command -v brew &>/dev/null; then
    return
  fi

  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_brew_packages() {
  local packages=(libpq neovim)
  local to_install=()

  for pkg in "${packages[@]}"; do
    if ! brew list "$pkg" &>/dev/null; then
      to_install+=("$pkg")
    fi
  done

  if [[ ${#to_install[@]} -gt 0 ]]; then
    echo "==> Installing Homebrew packages: ${to_install[*]}"
    brew install "${to_install[@]}"
  fi
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    return
  fi

  echo "==> Installing Oh My Zsh..."
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh_plugins() {
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  declare -A plugins=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
    [you-should-use]="https://github.com/MichaelAqworter/zsh-you-should-use"
    [zsh-vi-mode]="https://github.com/jeffreytse/zsh-vi-mode"
  )

  for plugin in "${!plugins[@]}"; do
    local dest="$zsh_custom/plugins/$plugin"
    if [[ ! -d "$dest" ]]; then
      echo "==> Installing ZSH plugin: $plugin"
      git clone --depth=1 "${plugins[$plugin]}" "$dest"
    fi
  done
}

create_symlinks() {
  local targets=("$HOME/.zshrc" "$HOME/.zsh")
  local sources=("$DOTFILES_DIR/.zshrc" "$DOTFILES_DIR/.zsh")
  local created=false

  for i in "${!targets[@]}"; do
    local target="${targets[$i]}"
    local source="${sources[$i]}"

    # Already correctly linked
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
      continue
    fi

    if [[ -e "$target" && ! -L "$target" ]]; then
      local backup="$target.backup.$(date +%Y%m%d%H%M%S)"
      echo "==> Backing up $target -> $backup"
      mv "$target" "$backup"
    elif [[ -L "$target" ]]; then
      rm "$target"
    fi

    ln -s "$source" "$target"
    echo "==> Linked $target -> $source"
    created=true
  done
}

main() {
  install_homebrew
  install_brew_packages
  install_oh_my_zsh
  install_zsh_plugins
  create_symlinks

  echo "==> Done!"
}

main
