if command -v zoxide >/dev/null 2>&1; then
  bash::init zoxide init bash || return
  zd() {
    if (( $# == 0 )); then
      builtin cd ~ || return
    elif [[ $1 == -* || -d $1 ]]; then
      builtin cd "$@" || return
    else
      z "$@" || return
      printf '󱞩 '
      pwd
    fi
  }
  alias cd='zd'
fi
