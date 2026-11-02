# Reuse the session's agent; only start one when no working agent is available.
if [[ ${OSTYPE} != darwin* ]] && command -v ssh-add >/dev/null 2>&1; then
  _ssh_agent_status=0
  ssh-add -l >/dev/null 2>&1 || _ssh_agent_status=$?
  if (( _ssh_agent_status == 2 )); then
    export SSH_AUTH_SOCK="${HOME}/.ssh/ssh-agent.sock"
    _ssh_agent_status=0
    ssh-add -l >/dev/null 2>&1 || _ssh_agent_status=$?
    if (( _ssh_agent_status == 2 )); then
      if mkdir -p -- "${HOME}/.ssh" && rm -f -- "${SSH_AUTH_SOCK}"; then
        bash::init ssh-agent -s -a "${SSH_AUTH_SOCK}" >/dev/null
      fi
    fi
  fi
  unset _ssh_agent_status
fi
