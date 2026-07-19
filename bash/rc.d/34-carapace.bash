if [[ $- == *i* && ${BASH_VERSINFO[0]} -ge 4 ]]; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'

  if command -v carapace >/dev/null 2>&1; then
    _carapace_init=''
    if ! _carapace_init="$(carapace _carapace bash)"; then
      printf 'error: failed to initialize carapace\n' >&2
    elif ! eval "${_carapace_init}"; then
      printf 'error: failed to load carapace initialization\n' >&2
    fi
    unset _carapace_init
  fi
fi
