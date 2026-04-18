if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# Lazy-load pyenv so startup stays fast.
pyenv() {
  unset -f pyenv
  if command -v pyenv >/dev/null 2>&1; then
    eval "$(command pyenv init -)"
  fi
  pyenv "$@"
}

if command -v fnm >/dev/null 2>&1; then
  _fnm_lazy_env() {
    unset -f fnm node npm _fnm_lazy_env
    eval "$(command fnm env)"
  }

  fnm() {
    _fnm_lazy_env
    fnm "$@"
  }

  node() {
    _fnm_lazy_env
    node "$@"
  }

  npm() {
    _fnm_lazy_env
    npm "$@"
  }
fi

if [[ ! -o interactive ]]; then
  return 0
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

if command -v try >/dev/null 2>&1; then
  eval "$(SHELL="$(command -v zsh)" command try init ~/Work/tries)"
fi

if command -v fzf >/dev/null 2>&1; then
  if [[ -f "${HOME}/.fzf.zsh" ]]; then
    source "${HOME}/.fzf.zsh"
  else
    [[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
    [[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
  fi
fi

[[ -f "${HOME}/.kube-ps1/kube-ps1.sh" ]] && source "${HOME}/.kube-ps1/kube-ps1.sh"

if [[ "${OSTYPE}" != darwin* ]]; then
  SSH_AUTH_SOCK_FILE="${HOME}/.ssh/ssh-agent.sock"
  export SSH_AUTH_SOCK="${SSH_AUTH_SOCK_FILE}"

  ssh_add_rc=0
  ssh-add -l >/dev/null 2>&1 || ssh_add_rc=$?
  if [[ ${ssh_add_rc} -eq 2 ]]; then
    rm -f "${SSH_AUTH_SOCK_FILE}"
    if ! eval "$(ssh-agent -s -a "${SSH_AUTH_SOCK_FILE}")" >/dev/null 2>&1; then
      echo "error: failed to start ssh-agent on ${SSH_AUTH_SOCK_FILE}" >&2
    fi
  fi
fi

if [[ "${TERM_PROGRAM}" == "vscode" ]] && command -v code >/dev/null 2>&1; then
  . "$(code --locate-shell-integration-path zsh)"
fi
