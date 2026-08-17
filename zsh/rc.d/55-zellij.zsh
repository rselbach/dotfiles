# Zellij layout helpers for dev tabs and pane swarms.

_zellij_shell_executable="$(command -v zsh)" || return 1

if [[ -z "${_zellij_shell_executable}" ]]; then
  printf 'Could not determine shell executable for Zellij helpers.\n' >&2
  return 1
fi

_zellij_require_session() {
  if [[ -z "${ZELLIJ:-}" ]]; then
    printf 'You must start zellij to use %s.\n' "${1}" >&2
    return 1
  fi
}

_zellij_kdl_escape() {
  local value
  value="${1}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "${value}"
}

_zellij_shell_quote() {
  local value
  value="${1}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//\$/\\\$}"
  value="${value//\`/\\\`}"
  printf '"%s"' "${value}"
}

_zellij_editor_command() {
  local editor
  local shell_command
  editor="${EDITOR:-nvim}"
  shell_command="$(_zellij_shell_quote "${_zellij_shell_executable}")" ||
    return 1
  printf '%s' "${editor} .; exec ${shell_command}"
}

_zellij_make_layout_file() {
  mktemp "${TMPDIR:-/tmp}/${1}.XXXXXX"
}

_zellij_write_command_pane() {
  local layout_path
  local indent
  local title
  local pane_command
  local focus
  local header

  layout_path="${1}"
  indent="${2}"
  title="${3}"
  pane_command="${4}"
  focus="${5}"
  header="${indent}pane"

  if [[ "${focus}" == "true" ]]; then
    header="${header} focus=true"
  fi

  header="${header} command=\"$(_zellij_kdl_escape \
    "${_zellij_shell_executable}")\""

  if [[ -n "${title}" ]]; then
    header="${header} name=\"$(_zellij_kdl_escape "${title}")\""
  fi

  {
    printf '%s {\n' "${header}"
    printf \
      '%s  args "-lc" "%s"\n' \
      "${indent}" "$(_zellij_kdl_escape "${pane_command}")"
    printf '%s}\n' "${indent}"
  } >> "${layout_path}"
}

_zellij_write_dev_layout() {
  local layout_path
  local ai
  local ai2
  local editor_command
  local shell_command

  layout_path="${1}"
  ai="${2}"
  ai2="${3}"
  editor_command="$(_zellij_editor_command)" || return 1
  shell_command="$(_zellij_shell_quote "${_zellij_shell_executable}")" ||
    return 1

  {
    printf 'layout {\n'
    printf '  default_tab_template {\n'
    printf '    pane size=1 borderless=true {\n'
    printf '      plugin location="tab-bar"\n'
    printf '    }\n'
    printf '    children\n'
    printf '    pane size=1 borderless=true {\n'
    printf '      plugin location="status-bar"\n'
    printf '    }\n'
    printf '  }\n'
    printf '  tab split_direction="horizontal" {\n'
    printf '    pane size="85%%" split_direction="vertical" {\n'
  } > "${layout_path}" || return 1

  _zellij_write_command_pane \
    "${layout_path}" '      ' 'editor' "${editor_command}" true || return 1

  if [[ -n "${ai2}" ]]; then
    printf \
      '      pane size="30%%" split_direction="horizontal" {\n' \
      >> "${layout_path}" || return 1
    _zellij_write_command_pane \
      "${layout_path}" '        ' "${ai}" \
      "${ai}; exec ${shell_command}" false || return 1
    _zellij_write_command_pane \
      "${layout_path}" '        ' "${ai2}" \
      "${ai2}; exec ${shell_command}" false || return 1
    printf '      }\n' >> "${layout_path}" || return 1
  else
    _zellij_write_command_pane \
      "${layout_path}" '      ' "${ai}" \
      "${ai}; exec ${shell_command}" false || return 1
  fi

  printf '    }\n' >> "${layout_path}" || return 1
  _zellij_write_command_pane \
    "${layout_path}" '    ' 'shell' "exec ${shell_command}" false || return 1

  {
    printf '  }\n'
    printf '}\n'
  } >> "${layout_path}"
}

_zellij_write_swarm_tree() {
  local layout_path
  local indent
  local count
  local depth
  local pane_command
  local focus_first
  local split_direction
  local left_count
  local right_count
  local shell_command

  layout_path="${1}"
  indent="${2}"
  count="${3}"
  depth="${4}"
  pane_command="${5}"
  focus_first="${6}"

  if (( count == 1 )); then
    shell_command="$(_zellij_shell_quote \
      "${_zellij_shell_executable}")" || return 1
    _zellij_write_command_pane \
      "${layout_path}" "${indent}" '' \
      "${pane_command}; exec ${shell_command}" "${focus_first}"
    return
  fi

  if (( depth % 2 == 0 )); then
    split_direction='vertical'
  else
    split_direction='horizontal'
  fi

  left_count=$(( (count + 1) / 2 ))
  right_count=$(( count / 2 ))

  printf \
    '%spane split_direction="%s" {\n' \
    "${indent}" "${split_direction}" >> "${layout_path}" || return 1

  _zellij_write_swarm_tree \
    "${layout_path}" \
    "${indent}  " \
    "${left_count}" \
    "$(( depth + 1 ))" \
    "${pane_command}" \
    "${focus_first}" || return 1
  _zellij_write_swarm_tree \
    "${layout_path}" \
    "${indent}  " \
    "${right_count}" \
    "$(( depth + 1 ))" \
    "${pane_command}" \
    false || return 1

  printf '%s}\n' "${indent}" >> "${layout_path}"
}

_zellij_write_swarm_layout() {
  local layout_path
  local pane_count
  local pane_command

  layout_path="${1}"
  pane_count="${2}"
  pane_command="${3}"

  {
    printf 'layout {\n'
    printf '  default_tab_template {\n'
    printf '    pane size=1 borderless=true {\n'
    printf '      plugin location="tab-bar"\n'
    printf '    }\n'
    printf '    children\n'
    printf '    pane size=1 borderless=true {\n'
    printf '      plugin location="status-bar"\n'
    printf '    }\n'
    printf '  }\n'
    printf '  tab {\n'
  } > "${layout_path}" || return 1

  _zellij_write_swarm_tree \
    "${layout_path}" '    ' "${pane_count}" 0 "${pane_command}" true ||
    return 1

  {
    printf '  }\n'
    printf '}\n'
  } >> "${layout_path}"
}

# Create a Zellij dev layout with editor, AI, and terminal.
# Usage: zdl <c|cx|codex|other_ai> [<second_ai>]
zdl() {
  local current_dir
  local tab_name
  local layout_path
  local ai
  local ai2
  local exit_code
  local cleanup_code

  if [[ -z "${1:-}" ]]; then
    printf 'Usage: zdl <c|cx|codex|other_ai> [<second_ai>]\n' >&2
    return 1
  fi

  _zellij_require_session zdl || return 1

  current_dir="${PWD}"
  tab_name="$(basename "${current_dir}")" || return 1
  ai="${1}"
  ai2="${2:-}"

  layout_path="$(_zellij_make_layout_file zdl)" || return 1
  _zellij_write_dev_layout "${layout_path}" "${ai}" "${ai2}" || {
    command rm -f -- "${layout_path}"
    return 1
  }

  zellij action new-tab \
    --layout "${layout_path}" \
    --cwd "${current_dir}" \
    --name "${tab_name}"
  exit_code=$?

  command rm -f -- "${layout_path}"
  cleanup_code=$?

  if (( exit_code != 0 )); then
    return "${exit_code}"
  fi

  return "${cleanup_code}"
}

# Create multiple dev tabs with one per subdirectory in the current directory.
# Usage: zdlm <c|cx|codex|other_ai> [<second_ai>]
zdlm() {
  local ai
  local ai2
  local base_dir
  local layout_path
  local session_name
  local first_tab_name
  local dir
  local dir_path
  local found_dirs
  local exit_code
  local cleanup_code

  if [[ -z "${1:-}" ]]; then
    printf 'Usage: zdlm <c|cx|codex|other_ai> [<second_ai>]\n' >&2
    return 1
  fi

  _zellij_require_session zdlm || return 1

  ai="${1}"
  ai2="${2:-}"
  base_dir="${PWD}"
  found_dirs=false
  exit_code=0
  session_name="$(basename "${base_dir}")" || return 1
  session_name="${session_name//[.:]/-}"

  zellij action rename-session "${session_name}" || return 1

  layout_path="$(_zellij_make_layout_file zdlm)" || return 1
  _zellij_write_dev_layout "${layout_path}" "${ai}" "${ai2}" || {
    command rm -f -- "${layout_path}"
    return 1
  }

  for dir in "${base_dir}"/*/; do
    [[ -d "${dir}" ]] || continue

    found_dirs=true
    dir_path="${dir%/}"

    if [[ -z "${first_tab_name}" ]]; then
      first_tab_name="$(basename "${dir_path}")" || {
        exit_code=1
        break
      }
    fi

    if ! zellij action new-tab \
      --layout "${layout_path}" \
      --cwd "${dir_path}" \
      --name "$(basename "${dir_path}")"; then
      exit_code=1
      break
    fi
  done

  command rm -f -- "${layout_path}"
  cleanup_code=$?

  if [[ "${found_dirs}" == false ]]; then
    printf 'zdlm: no subdirectories found in %s\n' "${base_dir}" >&2
    return 1
  fi

  if (( exit_code != 0 )); then
    return "${exit_code}"
  fi

  if (( cleanup_code != 0 )); then
    return "${cleanup_code}"
  fi

  zellij action go-to-tab-name "${first_tab_name}"
}

# Create a multi-pane swarm tab with the same command started in each pane.
# Usage: zsl <pane_count> <command>
zsl() {
  local pane_count
  local pane_command
  local current_dir
  local tab_name
  local layout_path
  local exit_code
  local cleanup_code

  if [[ -z "${1:-}" || -z "${2:-}" ]]; then
    printf 'Usage: zsl <pane_count> <command>\n' >&2
    return 1
  fi

  _zellij_require_session zsl || return 1

  pane_count="${1}"
  shift
  pane_command="${*}"
  current_dir="${PWD}"
  tab_name="$(basename "${current_dir}")" || return 1

  if ! [[ "${pane_count}" =~ ^[0-9]+$ ]] || (( pane_count < 1 )); then
    printf 'zsl: pane_count must be a positive integer\n' >&2
    return 1
  fi

  layout_path="$(_zellij_make_layout_file zsl)" || return 1
  _zellij_write_swarm_layout \
    "${layout_path}" "${pane_count}" "${pane_command}" || {
    command rm -f -- "${layout_path}"
    return 1
  }

  zellij action new-tab \
    --layout "${layout_path}" \
    --cwd "${current_dir}" \
    --name "${tab_name}"
  exit_code=$?

  command rm -f -- "${layout_path}"
  cleanup_code=$?

  if (( exit_code != 0 )); then
    return "${exit_code}"
  fi

  return "${cleanup_code}"
}
