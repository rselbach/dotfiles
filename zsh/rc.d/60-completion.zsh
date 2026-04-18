if [[ ! -o interactive ]]; then
  return 0
fi

if ! typeset -f compdef >/dev/null 2>&1; then
  autoload -Uz compinit
  compinit -i
fi

zstyle ':completion:*' menu false
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
if command -v carapace >/dev/null 2>&1; then
  zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
  source <(carapace _carapace)
fi
