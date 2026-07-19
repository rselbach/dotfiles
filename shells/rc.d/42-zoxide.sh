if command -v zoxide >/dev/null 2>&1; then
  _zoxide_init=''
  # shellcheck disable=SC2154
  if ! _zoxide_init="$(zoxide init "${_rc_shell}")"; then
    printf 'zoxide: failed to generate %s initialization\n' \
      "${_rc_shell}" >&2
  elif ! eval "${_zoxide_init}"; then
    printf 'zoxide: failed to evaluate %s initialization\n' \
      "${_rc_shell}" >&2
  else
    alias cd='zd'

    zd() {
      if (( $# == 0 )); then
        builtin cd ~ || return
      elif [[ -d $1 ]]; then
        builtin cd "$1" || return
      else
        if ! z "$@"; then
          printf '%s\n' 'Error: Directory not found' >&2
          return 1
        fi

        printf '󱞩 '
        pwd
      fi
    }
  fi
  unset _zoxide_init
fi
