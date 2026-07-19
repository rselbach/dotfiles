[[ -o interactive ]] || return 0

if command -v fzf >/dev/null 2>&1; then
  if [[ -f "${HOME}/.fzf.zsh" ]]; then
    if ! source "${HOME}/.fzf.zsh"; then
      printf '%s\n' 'fzf: failed to load ~/.fzf.zsh' >&2
    fi
    return 0
  fi

  _fzf_completion="${HOMEBREW_PREFIX:-}/opt/fzf/shell/completion.zsh"
  _fzf_bindings="${HOMEBREW_PREFIX:-}/opt/fzf/shell/key-bindings.zsh"
  if [[ ! -f "${_fzf_completion}" ]]; then
    _fzf_completion='/usr/share/fzf/completion.zsh'
  fi
  if [[ ! -f "${_fzf_bindings}" ]]; then
    _fzf_bindings='/usr/share/fzf/key-bindings.zsh'
  fi
  _fzf_loaded='false'

  if [[ -f "${_fzf_completion}" ]]; then
    if ! source "${_fzf_completion}"; then
      printf '%s\n' 'fzf: failed to load Zsh completion' >&2
    else
      _fzf_loaded='true'
    fi
  fi
  if [[ -f "${_fzf_bindings}" ]]; then
    if ! source "${_fzf_bindings}"; then
      printf '%s\n' 'fzf: failed to load Zsh key bindings' >&2
    else
      _fzf_loaded='true'
    fi
  fi

  if [[ "${_fzf_loaded}" == 'false' ]]; then
    _fzf_init=''
    if ! _fzf_init="$(fzf --zsh)"; then
      printf '%s\n' 'fzf: failed to generate Zsh initialization' >&2
    elif ! eval "${_fzf_init}"; then
      printf '%s\n' 'fzf: failed to evaluate Zsh initialization' >&2
    fi
    unset _fzf_init
  fi
  unset _fzf_completion _fzf_bindings _fzf_loaded
fi
