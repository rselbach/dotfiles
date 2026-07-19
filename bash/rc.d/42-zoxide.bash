if command -v zoxide >/dev/null 2>&1; then
  if zoxide_init_output="$(zoxide init bash)"; then
    if eval "${zoxide_init_output}"; then
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
    else
      printf '%s\n' 'zoxide: failed to evaluate Bash initialization' >&2
    fi
  else
    printf '%s\n' 'zoxide: failed to generate Bash initialization' >&2
  fi
  unset zoxide_init_output
fi
