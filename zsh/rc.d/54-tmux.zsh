# Snapshot Zsh's path for helpers invoked after startup.
_tmux_shell_executable="$(command -v zsh)" || _tmux_shell_executable='zsh'

_tmux_quote() {
  local value="${1}"
  local prefix

  printf "'"
  while [[ "${value}" == *"'"* ]]; do
    prefix="${value%%\'*}"
    printf '%s%s' "${prefix}" "'\\''"
    value="${value#*\'}"
  done
  printf "%s'" "${value}"
}

_tmux_login_command="$(_tmux_quote "${_tmux_shell_executable}") -l"

alias t='tmux attach || tmux new -s Work'
alias tx='tmux attach || tmux new'

# Create a Tmux dev layout with editor, AI, and terminal.
# Usage: tdl <c|cx|codex|other_ai> [<second_ai>]
tdl() {
  local current_dir
  local editor_pane
  local ai_pane
  local ai2_pane
  local ai
  local ai2

  if [[ -z "${1:-}" ]]; then
    printf 'Usage: tdl <c|cx|codex|other_ai> [<second_ai>]\n' >&2
    return 1
  fi

  if [[ -z "${TMUX:-}" ]]; then
    printf 'You must start tmux to use tdl.\n' >&2
    return 1
  fi

  current_dir="${PWD}"
  editor_pane="${TMUX_PANE}"
  ai="${1}"
  ai2="${2:-}"

  tmux rename-window \
    -t "${editor_pane}" "$(basename "${current_dir}")" || return 1

  tmux split-window \
    -v -p 15 -t "${editor_pane}" -c "${current_dir}" \
    "${_tmux_login_command}" || return 1

  ai_pane="$(
    tmux split-window \
      -h -p 30 -t "${editor_pane}" -c "${current_dir}" \
      -P -F '#{pane_id}' "${_tmux_login_command}"
  )" || return 1

  if [[ -n "${ai2}" ]]; then
    ai2_pane="$(
      tmux split-window \
        -v -t "${ai_pane}" -c "${current_dir}" -P -F '#{pane_id}' \
        "${_tmux_login_command}"
    )" || return 1
    tmux send-keys -t "${ai2_pane}" "${ai2}" C-m || return 1
  fi

  tmux send-keys -t "${ai_pane}" "${ai}" C-m || return 1
  tmux send-keys -t "${editor_pane}" "${EDITOR} ." C-m || return 1
  tmux select-pane -t "${editor_pane}" || return 1
}

# Create multiple tdl windows, one per subdirectory in the current directory.
# Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]
tdlm() {
  local ai
  local ai2
  local base_dir
  local first
  local dir
  local dirpath
  local pane_id
  local session_name
  local dirpath_quoted
  local ai_quoted
  local ai2_quoted
  local tdl_command

  if [[ -z "${1:-}" ]]; then
    printf 'Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]\n' >&2
    return 1
  fi

  if [[ -z "${TMUX:-}" ]]; then
    printf 'You must start tmux to use tdlm.\n' >&2
    return 1
  fi

  ai="${1}"
  ai2="${2:-}"
  base_dir="${PWD}"
  first='true'
  session_name="$(basename "${base_dir}")" || return 1
  session_name="${session_name//[.:]/-}"

  tmux rename-session "${session_name}" || return 1

  for dir in "${base_dir}"/*/; do
    [[ -d "${dir}" ]] || continue
    dirpath="${dir%/}"
    dirpath_quoted="$(_tmux_quote "${dirpath}")" || return 1
    ai_quoted="$(_tmux_quote "${ai}")" || return 1
    tdl_command="tdl ${ai_quoted}"
    if [[ -n "${ai2}" ]]; then
      ai2_quoted="$(_tmux_quote "${ai2}")" || return 1
      tdl_command+=" ${ai2_quoted}"
    fi

    if [[ "${first}" == 'true' ]]; then
      tmux send-keys \
        -t "${TMUX_PANE}" \
        "cd ${dirpath_quoted} && ${tdl_command}" C-m || return 1
      first='false'
    else
      pane_id="$(
        tmux new-window \
          -c "${dirpath}" -P -F '#{pane_id}' \
          "${_tmux_login_command}"
      )" || return 1
      tmux send-keys -t "${pane_id}" "${tdl_command}" C-m || return 1
    fi
  done
}

# Create a multi-pane swarm layout with the same command started in each pane.
# Usage: tsl <pane_count> <command>
tsl() {
  local count
  local cmd
  local current_dir
  local -a panes
  local new_pane
  local split_target
  local first_pane
  local pane

  if [[ -z "${1:-}" || -z "${2:-}" ]]; then
    printf 'Usage: tsl <pane_count> <command>\n' >&2
    return 1
  fi

  if [[ -z "${TMUX:-}" ]]; then
    printf 'You must start tmux to use tsl.\n' >&2
    return 1
  fi

  count="${1}"
  cmd="${2}"
  current_dir="${PWD}"
  first_pane="${TMUX_PANE}"
  split_target="${first_pane}"

  tmux rename-window \
    -t "${first_pane}" "$(basename "${current_dir}")" || return 1

  panes+=("${first_pane}")

  while (( ${#panes[@]} < count )); do
    new_pane="$(
      tmux split-window \
        -h -t "${split_target}" -c "${current_dir}" -P -F '#{pane_id}' \
        "${_tmux_login_command}"
    )" || return 1
    panes+=("${new_pane}")
    split_target="${new_pane}"
    tmux select-layout -t "${first_pane}" tiled || return 1
  done

  for pane in "${panes[@]}"; do
    tmux send-keys -t "${pane}" "${cmd}" C-m || return 1
  done

  tmux select-pane -t "${first_pane}" || return 1
}
