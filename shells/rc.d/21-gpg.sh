if [[ $- == *i* ]]; then
  if GPG_TTY="$(tty)"; then
    export GPG_TTY
  else
    printf '%s\n' 'gpg: failed to determine terminal' >&2
  fi
fi
