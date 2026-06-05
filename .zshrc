# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode)
source $ZSH/oh-my-zsh.sh

# Load modular config
for conf in ~/.zsh/*.zsh; do
  source "$conf"
done

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/declanelias/.lmstudio/bin"
# End of LM Studio CLI section

