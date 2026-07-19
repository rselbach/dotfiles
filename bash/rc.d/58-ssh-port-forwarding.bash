# SSH port forwarding helpers.
_ssh_forward_valid_port() {
  local port="${1}"

  if ! [[ "${port}" =~ ^[0-9]+$ ]] \
    || (( 10#${port} < 1 || 10#${port} > 65535 )); then
    printf 'Invalid TCP port: %s\n' "${port}" >&2
    return 1
  fi
}

fip() {
  local host
  local port
  local exit_code

  if (( $# < 2 )); then
    printf 'Usage: fip <host> <port1> [port2] ...\n' >&2
    return 1
  fi

  host="${1}"
  shift

  for port in "$@"; do
    _ssh_forward_valid_port "${port}" || return 1
    ssh -f -N -L "${port}:localhost:${port}" "${host}"
    exit_code=$?
    if (( exit_code != 0 )); then
      return "${exit_code}"
    fi

    printf 'Forwarding localhost:%s -> %s:%s\n' \
      "${port}" "${host}" "${port}"
  done
}

dip() {
  local port
  local exit_code

  if (( $# == 0 )); then
    printf 'Usage: dip <port1> [port2] ...\n' >&2
    return 1
  fi

  for port in "$@"; do
    _ssh_forward_valid_port "${port}" || return 1
    pkill -f "ssh.*-L ${port}:localhost:${port}"
    exit_code=$?

    case "${exit_code}" in
      0)
        printf 'Stopped forwarding port %s\n' "${port}"
        ;;
      1)
        printf 'No forwarding on port %s\n' "${port}"
        ;;
      *)
        return "${exit_code}"
        ;;
    esac
  done
}

lip() {
  local pids
  local exit_code
  local pid
  local pid_list

  pids="$(pgrep -f 'ssh.*-L [0-9]+:localhost:[0-9]+')"
  exit_code=$?

  case "${exit_code}" in
    0) ;;
    1)
      printf 'No active forwards\n'
      return 0
      ;;
    *)
      return "${exit_code}"
      ;;
  esac

  pid_list=""
  while IFS= read -r pid; do
    pid_list="${pid_list:+${pid_list},}${pid}"
  done <<< "${pids}"

  ps -p "${pid_list}" -o pid=,command=
}
