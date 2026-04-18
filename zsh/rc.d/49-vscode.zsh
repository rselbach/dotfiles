if [[ ! -o interactive ]]; then
  return 0
fi

if [[ "${TERM_PROGRAM}" == "vscode" ]] && command -v code >/dev/null 2>&1; then
  . "$(code --locate-shell-integration-path zsh)"
fi
