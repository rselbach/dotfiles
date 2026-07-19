[[ $- == *i* ]] || return 0

if command -v fzf >/dev/null 2>&1; then
  if [[ -f "${HOME}/.fzf.bash" ]]; then
    # shellcheck source=/dev/null
    if ! source "${HOME}/.fzf.bash"; then
      printf '%s\n' 'fzf: failed to load ~/.fzf.bash' >&2
    fi
    return 0
  fi

  _fzf_completion="${HOMEBREW_PREFIX:-}/opt/fzf/shell/completion.bash"
  _fzf_bindings="${HOMEBREW_PREFIX:-}/opt/fzf/shell/key-bindings.bash"
  if [[ ! -f "${_fzf_completion}" ]]; then
    _fzf_completion='/usr/share/fzf/completion.bash'
  fi
  if [[ ! -f "${_fzf_bindings}" ]]; then
    _fzf_bindings='/usr/share/fzf/key-bindings.bash'
  fi
  _fzf_loaded='false'

  if [[ -f "${_fzf_completion}" ]]; then
    # shellcheck source=/dev/null
    if ! source "${_fzf_completion}"; then
      printf '%s\n' 'fzf: failed to load Bash completion' >&2
    else
      _fzf_loaded='true'
    fi
  fi
  if [[ -f "${_fzf_bindings}" ]]; then
    # shellcheck source=/dev/null
    if ! source "${_fzf_bindings}"; then
      printf '%s\n' 'fzf: failed to load Bash key bindings' >&2
    else
      _fzf_loaded='true'
    fi
  fi

  if [[ "${_fzf_loaded}" == 'false' ]]; then
    _fzf_init=''
    if ! _fzf_init="$(fzf --bash)"; then
      printf '%s\n' 'fzf: failed to generate Bash initialization' >&2
    elif ! eval "${_fzf_init}"; then
      printf '%s\n' 'fzf: failed to evaluate Bash initialization' >&2
    fi
    unset _fzf_init
  fi
  unset _fzf_completion _fzf_bindings _fzf_loaded
fi
