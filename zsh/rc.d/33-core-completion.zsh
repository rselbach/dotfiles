if [[ ! -o interactive ]]; then
  return 0
fi

if ! typeset -f compdef >/dev/null 2>&1; then
  autoload -Uz compinit
  compinit -i
fi

zstyle ':completion:*' menu false
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
