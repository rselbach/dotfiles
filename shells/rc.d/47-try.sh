[[ $- == *i* ]] || return 0

if command -v try >/dev/null 2>&1; then
  _try_init=''
  # shellcheck disable=SC2154
  if [[ "${_rc_shell}" == 'bash' ]]; then
    _try_shell_executable="${BASH}"
  else
    _try_shell_executable="$(command -v zsh)" || {
      printf '%s\n' 'try: failed to locate Zsh executable' >&2
      return 0
    }
  fi

  if ! _try_init="$(
    SHELL="${_try_shell_executable}" \
      command try init "${HOME}/Work/tries"
  )"; then
    printf 'try: failed to generate %s initialization\n' "${_rc_shell}" >&2
  elif ! eval "${_try_init}"; then
    printf 'try: failed to evaluate %s initialization\n' "${_rc_shell}" >&2
  fi
  unset _try_init _try_shell_executable
fi
