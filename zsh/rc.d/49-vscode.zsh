[[ $- == *i* ]] || return 0

if [[ "${TERM_PROGRAM:-}" == 'vscode' ]] \
  && command -v code >/dev/null 2>&1; then
  _vscode_integration_path=''
  if ! _vscode_integration_path="$(
    code --locate-shell-integration-path zsh
  )"; then
    printf '%s\n' 'VS Code: failed to locate Zsh shell integration' >&2
  elif [[ ! -f "${_vscode_integration_path}" ]]; then
    printf '%s\n' 'VS Code: shell integration path is not a file' >&2
  else
    # shellcheck source=/dev/null
    if ! source "${_vscode_integration_path}"; then
      printf '%s\n' 'VS Code: failed to load shell integration' >&2
    fi
  fi
  unset _vscode_integration_path
fi
