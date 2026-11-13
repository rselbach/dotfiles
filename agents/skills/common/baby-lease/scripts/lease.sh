#!/usr/bin/env bash
# Hold or release the Baby lease that keeps the Mac awake while an agent works.
set -euo pipefail

readonly DURATION="2h"
readonly APP_TOOL="/Applications/Baby.app/Contents/Helpers/baby"

usage() {
  cat >&2 <<'USAGE'
Usage: lease.sh hold [LABEL]
       lease.sh release
USAGE
}

# find_baby prints the baby tool's path, or nothing when Baby isn't installed.
find_baby() {
  if command -v baby >/dev/null 2>&1; then
    command -v baby
  elif [[ -x "${APP_TOOL}" ]]; then
    echo "${APP_TOOL}"
  fi
}

# agent_pid prints the nearest ancestor that isn't a shell, which is the agent
# process whose exit should end the lease.
agent_pid() {
  local pid="${PPID}"
  local name
  while (( pid > 1 )); do
    name="$(ps -o comm= -p "${pid}")"
    name="${name##*/}"
    name="${name#-}"
    case "${name}" in
      bash | zsh | sh | dash | fish | env) ;;
      *)
        echo "${pid}"
        return 0
        ;;
    esac
    pid="$(ps -o ppid= -p "${pid}" | tr -d ' ')"
  done
  echo "lease.sh: could not find the agent process" >&2
  return 1
}

main() {
  local command="${1:-}"
  if [[ "${command}" != "hold" && "${command}" != "release" ]]; then
    usage
    return 2
  fi
  local baby
  baby="$(find_baby)"
  if [[ -z "${baby}" ]]; then
    echo "lease.sh: Baby is not installed; nothing to do" >&2
    return 0
  fi
  local pid
  pid="$(agent_pid)"
  local id="agent-${pid}"
  if [[ "${command}" == "release" ]]; then
    "${baby}" release "${id}"
    return
  fi
  local args=(hold --pid "${pid}" --id "${id}" --for "${DURATION}")
  if [[ -n "${2:-}" ]]; then
    args+=(--label "${2}")
  fi
  "${baby}" "${args[@]}"
}

main "$@"
