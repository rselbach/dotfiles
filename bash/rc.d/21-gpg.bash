if [[ -t 0 ]] && GPG_TTY=$(tty); then
  export GPG_TTY
fi
