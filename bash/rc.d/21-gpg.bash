if [[ $- == *i* && -t 0 ]]; then
  GPG_TTY="$(tty)" || return 1
  export GPG_TTY
fi
