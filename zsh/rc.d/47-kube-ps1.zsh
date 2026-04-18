export KUBE_PS1_NS_ENABLE=false

if [[ ! -o interactive ]]; then
  return 0
fi

[[ -f "${HOME}/.kube-ps1/kube-ps1.sh" ]] && source "${HOME}/.kube-ps1/kube-ps1.sh"
