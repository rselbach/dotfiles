[[ $- == *i* ]] || return 0

if command -v try >/dev/null 2>&1; then
  if try_init_output="$(
    SHELL="${BASH}" command try init "${HOME}/Work/tries"
  )"; then
    if ! eval "${try_init_output}"; then
      printf '%s\n' 'try: failed to evaluate Bash initialization' >&2
    fi
  else
    printf '%s\n' 'try: failed to generate Bash initialization' >&2
  fi
  unset try_init_output
fi
