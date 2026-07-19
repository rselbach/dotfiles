if [[ $- == *i* && "${OSTYPE}" != darwin* ]]; then
  SSH_AUTH_SOCK_FILE="${HOME}/.ssh/ssh-agent.sock"
  export SSH_AUTH_SOCK="${SSH_AUTH_SOCK_FILE}"

  _ssh_add_rc=0
  ssh-add -l >/dev/null 2>&1 || _ssh_add_rc=$?
  if (( _ssh_add_rc == 2 )); then
    if ! rm -f "${SSH_AUTH_SOCK_FILE}"; then
      printf 'error: failed to remove stale SSH agent socket: %s\n' \
        "${SSH_AUTH_SOCK_FILE}" >&2
    else
      _ssh_agent_output=''
      if ! _ssh_agent_output="$(
        ssh-agent -s -a "${SSH_AUTH_SOCK_FILE}" 2>&1
      )"; then
        printf 'error: failed to start ssh-agent on %s: %s\n' \
          "${SSH_AUTH_SOCK_FILE}" "${_ssh_agent_output}" >&2
      elif ! eval "${_ssh_agent_output}" >/dev/null; then
        printf 'error: failed to load ssh-agent environment for %s\n' \
          "${SSH_AUTH_SOCK_FILE}" >&2
      fi
    fi
  fi

  unset _ssh_add_rc _ssh_agent_output
fi
