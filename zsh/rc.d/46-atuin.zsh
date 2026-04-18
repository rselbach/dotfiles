if [[ ! -o interactive ]]; then
  return 0
fi

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi
