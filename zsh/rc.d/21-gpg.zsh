if [[ -o interactive ]]; then
  export GPG_TTY="$(tty)"
fi
