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


install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    return
  fi

  echo "==> Installing Oh My Zsh..."
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_brew_packages() {
  local packages=(neovim yabai skhd)

  for pkg in "${packages[@]}"; do
    if brew list "$pkg" &>/dev/null; then
      continue
    fi
    echo "==> Installing $pkg..."
    brew install "$pkg"
  done
}

install_zsh_plugins() {
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  local dest="$zsh_custom/plugins/zsh-vi-mode"
  if [[ ! -d "$dest" ]]; then
    echo "==> Installing ZSH plugin: zsh-vi-mode"
    git clone --depth=1 https://github.com/jeffreytse/zsh-vi-mode "$dest"
  fi

  dest="$zsh_custom/plugins/zsh-autosuggestions"
  if [[ ! -d "$dest" ]]; then
    echo "==> Installing ZSH plugin: zsh-autosuggestions"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$dest"
  fi

  dest="$zsh_custom/plugins/zsh-syntax-highlighting"
  if [[ ! -d "$dest" ]]; then
    echo "==> Installing ZSH plugin: zsh-syntax-highlighting"
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$dest"
  fi
}

create_symlinks() {
  local targets=("$HOME/.zshrc" "$HOME/.zsh" "$HOME/.config/yabai/yabairc" "$HOME/.config/skhd/skhdrc" "$HOME/.config/nvim")
  local sources=("$DOTFILES_DIR/.zshrc" "$DOTFILES_DIR/.zsh" "$DOTFILES_DIR/yabai/yabairc" "$DOTFILES_DIR/skhd/skhdrc" "$DOTFILES_DIR/nvim")
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

    mkdir -p "$(dirname "$target")"
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
