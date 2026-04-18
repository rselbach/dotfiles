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
