[[ $- == *i* ]] || return 0

if [[ "${TERM_PROGRAM:-}" == "vscode" ]] &&
  command -v code >/dev/null 2>&1; then
  if vscode_integration_path="$(
    code --locate-shell-integration-path bash
  )"; then
    if [[ -f "${vscode_integration_path}" ]]; then
      # shellcheck disable=SC1090
      if ! source "${vscode_integration_path}"; then
        printf '%s\n' 'VS Code: failed to load shell integration' >&2
      fi
    else
      printf '%s\n' 'VS Code: shell integration path is not a file' >&2
    fi
  else
    printf '%s\n' 'VS Code: failed to locate Bash shell integration' >&2
  fi
  unset vscode_integration_path
fi
