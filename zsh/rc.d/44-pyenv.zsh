# Lazy-load pyenv so startup stays fast.
pyenv() {
  unset -f pyenv
  if command -v pyenv >/dev/null 2>&1; then
    eval "$(command pyenv init -)"
  fi
  pyenv "$@"
}
