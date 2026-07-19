# Lazy-load pyenv so startup stays fast.
pyenv() {
  local pyenv_init_output

  unset -f pyenv
  if ! command -v pyenv >/dev/null 2>&1; then
    printf '%s\n' 'pyenv: command not found' >&2
    return 127
  fi
  if ! pyenv_init_output="$(command pyenv init - bash)"; then
    printf '%s\n' 'pyenv: failed to generate Bash initialization' >&2
    return 1
  fi
  if ! eval "${pyenv_init_output}"; then
    printf '%s\n' 'pyenv: failed to evaluate Bash initialization' >&2
    return 1
  fi
  pyenv "$@"
}
