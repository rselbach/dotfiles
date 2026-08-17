[[ -o interactive ]] || return 0

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'

if command -v carapace >/dev/null 2>&1; then
  zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
  _carapace_init=''
  if ! _carapace_init="$(carapace _carapace)"; then
    printf '%s\n' 'carapace: failed to generate Zsh initialization' >&2
  elif ! eval "${_carapace_init}"; then
    printf '%s\n' 'carapace: failed to evaluate Zsh initialization' >&2
  fi
  unset _carapace_init
fi
