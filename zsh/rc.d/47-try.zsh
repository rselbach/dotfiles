if [[ ! -o interactive ]]; then
  return 0
fi

if command -v try >/dev/null 2>&1; then
  eval "$(SHELL="$(command -v zsh)" command try init ~/Work/tries)"
fi
