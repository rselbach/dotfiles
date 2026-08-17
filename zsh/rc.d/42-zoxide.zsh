if command -v zoxide >/dev/null 2>&1; then
  _zoxide_init=''
  if ! _zoxide_init="$(zoxide init zsh)"; then
    printf '%s\n' 'zoxide: failed to generate Zsh initialization' >&2
  elif ! eval "${_zoxide_init}"; then
    printf '%s\n' 'zoxide: failed to evaluate Zsh initialization' >&2
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
