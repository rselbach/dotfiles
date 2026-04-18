export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"

if [[ ! -o interactive ]]; then
  return 0
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
