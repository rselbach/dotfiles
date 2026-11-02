export KUBE_PS1_NS_ENABLE=false

[[ $- == *i* ]] || return 0

if [[ -f "${HOME}/.kube-ps1/kube-ps1.sh" ]]; then
  # shellcheck source=/dev/null
  if ! source "${HOME}/.kube-ps1/kube-ps1.sh"; then
    printf '%s\n' 'kube-ps1: failed to load kube-ps1.sh' >&2
  fi
fi
