[[ $- == *i* ]] || return 0

if command -v try >/dev/null 2>&1; then
  _try_init=''
  _try_shell_executable="$(command -v zsh)" || {
    printf '%s\n' 'try: failed to locate Zsh executable' >&2
    return 0
  }

  if ! _try_init="$(
    SHELL="${_try_shell_executable}" \
      command try init "${HOME}/Work/tries"
  )"; then
    printf '%s\n' 'try: failed to generate Zsh initialization' >&2
  elif ! eval "${_try_init}"; then
    printf '%s\n' 'try: failed to evaluate Zsh initialization' >&2
  fi
  unset _try_init _try_shell_executable
fi
