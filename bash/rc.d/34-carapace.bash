if [[ $- == *i* && ${BASH_VERSINFO[0]} -ge 4 ]] \
  && command -v carapace >/dev/null 2>&1; then
  _carapace_init=''
  if ! _carapace_init="$(carapace _carapace bash)"; then
    printf '%s\n' 'carapace: failed to generate Bash initialization' >&2
  elif ! eval "${_carapace_init}"; then
    printf '%s\n' 'carapace: failed to evaluate Bash initialization' >&2
  fi
  unset _carapace_init
fi
