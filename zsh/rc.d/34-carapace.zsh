if [[ ! -o interactive ]]; then
  return 0
fi

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'

if command -v carapace >/dev/null 2>&1; then
  zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
  source <(carapace _carapace)
fi
