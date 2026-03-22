# Shorten branch names in prompt: declan/product-NUMBER-whatever -> declan/NUMBER
git_prompt_info() {
  local ref
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0

  local branch="${ref#refs/heads/}"

  if [[ $branch =~ ^declan/product-([0-9]+)- ]]; then
    branch="declan/${match[1]}"
  fi

  echo "$ZSH_THEME_GIT_PROMPT_PREFIX${branch}$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
}
