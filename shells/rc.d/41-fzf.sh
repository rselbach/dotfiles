# Tokyo Night FZF colors.
export FZF_DEFAULT_OPTS=" \
--color=bg+:#283457,bg:#1a1b26,spinner:#ff007c,hl:#2ac3de \
--color=fg:#c0caf5,header:#ff9e64,info:#545c7e,pointer:#ff007c \
--color=marker:#ff007c,fg+:#c0caf5,prompt:#2ac3de,hl+:#2ac3de \
--color=selected-bg:#283457"

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias eff='$EDITOR "$(ff)"'
