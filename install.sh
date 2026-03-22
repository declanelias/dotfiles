#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing dotfiles from $DOTFILES_DIR"

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for the rest of this script
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "==> Homebrew already installed"
fi

# --- Brew packages ---
echo "==> Installing Homebrew packages..."
brew install openssl@3 libpq neovim

# --- Oh My Zsh ---
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "==> Installing Oh My Zsh..."
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "==> Oh My Zsh already installed"
fi

# --- ZSH plugins ---
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

declare -A plugins=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
  [you-should-use]="https://github.com/MichaelAqworter/zsh-you-should-use"
  [zsh-vi-mode]="https://github.com/jeffreytse/zsh-vi-mode"
)

echo "==> Installing ZSH plugins..."
for plugin in "${!plugins[@]}"; do
  dest="$ZSH_CUSTOM/plugins/$plugin"
  if [[ ! -d "$dest" ]]; then
    echo "    Installing $plugin..."
    git clone --depth=1 "${plugins[$plugin]}" "$dest"
  else
    echo "    $plugin already installed"
  fi
done

# --- Symlinks ---
echo "==> Creating symlinks..."

# Back up existing files if they're not already symlinks
for target in "$HOME/.zshrc" "$HOME/.zsh"; do
  if [[ -e "$target" && ! -L "$target" ]]; then
    backup="$target.backup.$(date +%Y%m%d%H%M%S)"
    echo "    Backing up $target -> $backup"
    mv "$target" "$backup"
  elif [[ -L "$target" ]]; then
    rm "$target"
  fi
done

ln -s "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -s "$DOTFILES_DIR/.zsh" "$HOME/.zsh"

echo "    ~/.zshrc -> $DOTFILES_DIR/.zshrc"
echo "    ~/.zsh   -> $DOTFILES_DIR/.zsh"

echo ""
echo "==> Done! Restart your shell or run: source ~/.zshrc"
