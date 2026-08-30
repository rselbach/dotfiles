#!/usr/bin/env bash
# Wait until a tmux pane on an optional private socket contains matching text.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: wait-for-text.sh [-S socket-path] -t target -p pattern [options]

Poll a tmux pane for text and exit when found.

Options:
  -S, --socket-path  tmux socket path (passed to tmux -S)
  -t, --target       tmux target (session:window.pane), required
  -p, --pattern      regex pattern to look for, required
  -F, --fixed        treat pattern as a fixed string (grep -F)
  -T, --timeout      seconds to wait (integer, default: 15)
  -i, --interval     poll interval in seconds (default: 0.5)
  -l, --lines        history lines to inspect (integer, default: 1000)
  -h, --help         show this help
USAGE
}

main() {
  local socket_path=""
  local target=""
  local pattern=""
  local grep_flag="-E"
  local timeout=15
  local interval=0.5
  local lines=1000
  local start_epoch
  local deadline
  local pane_text
  local now
  local -a tmux_cmd=(tmux)

  while [[ $# -gt 0 ]]; do
    case "${1}" in
      -S | --socket-path)
        socket_path="${2-}"
        shift 2
        ;;
      -t | --target)
        target="${2-}"
        shift 2
        ;;
      -p | --pattern)
        pattern="${2-}"
        shift 2
        ;;
      -F | --fixed)
        grep_flag="-F"
        shift
        ;;
      -T | --timeout)
        timeout="${2-}"
        shift 2
        ;;
      -i | --interval)
        interval="${2-}"
        shift 2
        ;;
      -l | --lines)
        lines="${2-}"
        shift 2
        ;;
      -h | --help)
        usage
        return 0
        ;;
      *)
        printf 'Unknown option: %s\n' "${1}" >&2
        usage >&2
        return 1
        ;;
    esac
  done

  if [[ -z "${target}" || -z "${pattern}" ]]; then
    printf 'target and pattern are required\n' >&2
    usage >&2
    return 1
  fi

  if ! [[ "${timeout}" =~ ^[0-9]+$ ]]; then
    printf 'timeout must be an integer number of seconds\n' >&2
    return 1
  fi

  if ! [[ "${lines}" =~ ^[0-9]+$ ]]; then
    printf 'lines must be an integer\n' >&2
    return 1
  fi

  if ! command -v tmux >/dev/null 2>&1; then
    printf 'tmux not found in PATH\n' >&2
    return 1
  fi

  if [[ -n "${socket_path}" ]]; then
    tmux_cmd+=(-S "${socket_path}")
  fi

  start_epoch="$(date +%s)"
  deadline=$((start_epoch + timeout))

  while true; do
    if ! pane_text="$(
      "${tmux_cmd[@]}" capture-pane -p -J -t "${target}" \
        -S "-${lines}" 2>/dev/null
    )"; then
      pane_text=""
    fi

    if grep "${grep_flag}" -- "${pattern}" \
      <<<"${pane_text}" >/dev/null 2>&1; then
      return 0
    fi

    now="$(date +%s)"
    if ((now >= deadline)); then
      printf 'Timed out after %ss waiting for pattern: %s\n' \
        "${timeout}" "${pattern}" >&2
      printf 'Last %s lines from %s:\n' "${lines}" "${target}" >&2
      printf '%s\n' "${pane_text}" >&2
      return 1
    fi

    sleep "${interval}"
  done
}

main "$@"
