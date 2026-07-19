# Tokyo Night FZF colors.
export FZF_DEFAULT_OPTS=" \
--color=bg+:#283457,bg:#1a1b26,spinner:#ff007c,hl:#2ac3de \
--color=fg:#c0caf5,header:#ff9e64,info:#545c7e,pointer:#ff007c \
--color=marker:#ff007c,fg+:#c0caf5,prompt:#2ac3de,hl+:#2ac3de \
--color=selected-bg:#283457"

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias eff='$EDITOR "$(ff)"'

[[ $- == *i* ]] || return 0

if command -v fzf >/dev/null 2>&1; then
  if [[ -f "${HOME}/.fzf.bash" ]]; then
    # shellcheck disable=SC1091
    if ! source "${HOME}/.fzf.bash"; then
      printf '%s\n' 'fzf: failed to load ~/.fzf.bash' >&2
    fi
  else
    if [[ -f /usr/share/fzf/completion.bash ]]; then
      # shellcheck disable=SC1091
      if ! source /usr/share/fzf/completion.bash; then
        printf '%s\n' 'fzf: failed to load Bash completion' >&2
      fi
    fi
    if [[ -f /usr/share/fzf/key-bindings.bash ]]; then
      # shellcheck disable=SC1091
      if ! source /usr/share/fzf/key-bindings.bash; then
        printf '%s\n' 'fzf: failed to load Bash key bindings' >&2
      fi
    fi

    if [[ ! -f /usr/share/fzf/completion.bash \
      && ! -f /usr/share/fzf/key-bindings.bash ]]; then
      _fzf_init=''
      if ! _fzf_init="$(fzf --bash)"; then
        printf '%s\n' 'fzf: failed to generate Bash initialization' >&2
      elif ! eval "${_fzf_init}"; then
        printf '%s\n' 'fzf: failed to load Bash initialization' >&2
      fi
      unset _fzf_init
    fi
  fi
fi
