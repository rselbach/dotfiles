#!/usr/bin/env bash
# Append a validated row to a show-me-your-work decision log in TSV format.
# Usage: log.sh <logfile> <phase> <decision> <why> <evidence> <result>
set -euo pipefail

readonly LOG_HEADER=$'ts\tphase\tdecision\twhy\tevidence\tresult'

clean_cell() {
  local value="${1}"

  value="${value//$'\t'/ }"
  value="${value//$'\n'/ }"
  value="${value//$'\r'/ }"

  case "${value}" in
    =* | +* | -* | @*) printf "'%s" "${value}" ;;
    *) printf '%s' "${value}" ;;
  esac
}

ensure_log() {
  local logfile="${1}"
  local header

  if [[ ! -s "${logfile}" ]]; then
    printf '%s\n' "${LOG_HEADER}" > "${logfile}"
    return
  fi

  IFS= read -r header < "${logfile}" || true
  if [[ "${header}" == "${LOG_HEADER}" ]]; then
    return
  fi

  printf 'error: %s does not have the show-me-your-work header\n' \
    "${logfile}" >&2
  return 1
}

main() {
  if (( $# != 6 )); then
    printf '%s\n' \
      'usage: log.sh <logfile> <phase> <decision> <why> <evidence> <result>' \
      >&2
    return 1
  fi

  local logfile="${1}"
  local logdir
  local timestamp
  shift

  logdir="$(dirname "${logfile}")"
  if [[ "${logdir}" != "." && ! -d "${logdir}" ]]; then
    mkdir -p "${logdir}"
  fi

  ensure_log "${logfile}"
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${timestamp}" \
    "$(clean_cell "${1}")" \
    "$(clean_cell "${2}")" \
    "$(clean_cell "${3}")" \
    "$(clean_cell "${4}")" \
    "$(clean_cell "${5}")" \
    >> "${logfile}"
}

main "$@"
