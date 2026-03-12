# Zellij layout helpers for dev tabs and pane swarms.

_zellij_require_session() {
  if [[ -z "${ZELLIJ}" ]]; then
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

_zellij_editor_command() {
  local editor
  editor="${EDITOR:-nvim}"
  printf '%s' "${editor} .; exec zsh"
}

_zellij_make_layout_file() {
  mktemp "${TMPDIR:-/tmp}/${1}.XXXXXX.kdl"
}

_zellij_write_command_pane() {
  local layout_path indent title pane_command focus header
  layout_path="${1}"
  indent="${2}"
  title="${3}"
  pane_command="${4}"
  focus="${5}"

  header="${indent}pane"

  if [[ "${focus}" == "true" ]]; then
    header="${header} focus=true"
  fi

  header="${header} command=\"zsh\""

  if [[ -n "${title}" ]]; then
    header="${header} name=\"$(_zellij_kdl_escape "${title}")\""
  fi

  {
    printf '%s {\n' "${header}"
    printf '%s  args "-lc" "%s"\n' "${indent}" "$(_zellij_kdl_escape "${pane_command}")"
    printf '%s}\n' "${indent}"
  } >> "${layout_path}"
}

_zellij_write_dev_layout() {
  local layout_path ai ai2 editor_command
  layout_path="${1}"
  ai="${2}"
  ai2="${3}"
  editor_command="$(_zellij_editor_command)"

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
  } > "${layout_path}"

  _zellij_write_command_pane "${layout_path}" '      ' 'editor' "${editor_command}" true

  if [[ -n "${ai2}" ]]; then
    {
      printf '      pane size="30%%" split_direction="horizontal" {\n'
    } >> "${layout_path}"
    _zellij_write_command_pane "${layout_path}" '        ' "${ai}" "${ai}; exec zsh" false
    _zellij_write_command_pane "${layout_path}" '        ' "${ai2}" "${ai2}; exec zsh" false
    {
      printf '      }\n'
    } >> "${layout_path}"
  else
    _zellij_write_command_pane "${layout_path}" '      ' "${ai}" "${ai}; exec zsh" false
  fi

  {
    printf '    }\n'
    printf '    pane size="15%%" name="shell"\n'
    printf '  }\n'
    printf '}\n'
  } >> "${layout_path}"
}

_zellij_write_swarm_tree() {
  local layout_path indent count depth pane_command focus_first split_direction left_count right_count
  layout_path="${1}"
  indent="${2}"
  count="${3}"
  depth="${4}"
  pane_command="${5}"
  focus_first="${6}"

  if (( count == 1 )); then
    _zellij_write_command_pane "${layout_path}" "${indent}" '' "${pane_command}; exec zsh" "${focus_first}"
    return
  fi

  if (( depth % 2 == 0 )); then
    split_direction='vertical'
  else
    split_direction='horizontal'
  fi

  left_count=$(( (count + 1) / 2 ))
  right_count=$(( count / 2 ))

  {
    printf '%spane split_direction="%s" {\n' "${indent}" "${split_direction}"
  } >> "${layout_path}"

  _zellij_write_swarm_tree \
    "${layout_path}" \
    "${indent}  " \
    "${left_count}" \
    "$(( depth + 1 ))" \
    "${pane_command}" \
    "${focus_first}"
  _zellij_write_swarm_tree \
    "${layout_path}" \
    "${indent}  " \
    "${right_count}" \
    "$(( depth + 1 ))" \
    "${pane_command}" \
    false

  {
    printf '%s}\n' "${indent}"
  } >> "${layout_path}"
}

_zellij_write_swarm_layout() {
  local layout_path pane_count pane_command
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
  } > "${layout_path}"

  _zellij_write_swarm_tree "${layout_path}" '    ' "${pane_count}" 0 "${pane_command}" true

  {
    printf '  }\n'
    printf '}\n'
  } >> "${layout_path}"
}

# Create a Zellij dev layout with editor, AI, and terminal.
# Usage: zdl <c|cx|codex|other_ai> [<second_ai>]
zdl() {
  if [[ -z "${1}" ]]; then
    printf 'Usage: zdl <c|cx|codex|other_ai> [<second_ai>]\n' >&2
    return 1
  fi

  _zellij_require_session zdl || return 1

  local current_dir tab_name layout_path ai ai2
  current_dir="${PWD}"
  tab_name="$(basename "${current_dir}")"
  ai="${1}"
  ai2="${2}"

  layout_path="$(_zellij_make_layout_file zdl)" || return 1
  _zellij_write_dev_layout "${layout_path}" "${ai}" "${ai2}" || {
    command rm -f -- "${layout_path}"
    return 1
  }

  zellij action new-tab --layout "${layout_path}" --cwd "${current_dir}" --name "${tab_name}"
  local exit_code=$?

  command rm -f -- "${layout_path}"
  return "${exit_code}"
}

# Create multiple dev tabs with one per subdirectory in the current directory.
# Usage: zdlm <c|cx|codex|other_ai> [<second_ai>]
zdlm() {
  if [[ -z "${1}" ]]; then
    printf 'Usage: zdlm <c|cx|codex|other_ai> [<second_ai>]\n' >&2
    return 1
  fi

  _zellij_require_session zdlm || return 1

  local ai ai2 base_dir layout_path session_name first_tab_name dir dir_path found_dirs exit_code
  ai="${1}"
  ai2="${2}"
  base_dir="${PWD}"
  found_dirs=false
  exit_code=0
  session_name="$(basename "${base_dir}" | tr '.:' '--')"

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
      first_tab_name="$(basename "${dir_path}")"
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

  if [[ "${found_dirs}" == false ]]; then
    printf 'zdlm: no subdirectories found in %s\n' "${base_dir}" >&2
    return 1
  fi

  if (( exit_code != 0 )); then
    return "${exit_code}"
  fi

  zellij action go-to-tab-name "${first_tab_name}"
}

# Create a multi-pane swarm tab with the same command started in each pane.
# Usage: zsl <pane_count> <command>
zsl() {
  if [[ -z "${1}" || -z "${2}" ]]; then
    printf 'Usage: zsl <pane_count> <command>\n' >&2
    return 1
  fi

  _zellij_require_session zsl || return 1

  local pane_count pane_command current_dir tab_name layout_path
  pane_count="${1}"
  shift
  pane_command="${*}"
  current_dir="${PWD}"
  tab_name="$(basename "${current_dir}")"

  if ! [[ "${pane_count}" =~ ^[0-9]+$ ]] || (( pane_count < 1 )); then
    printf 'zsl: pane_count must be a positive integer\n' >&2
    return 1
  fi

  layout_path="$(_zellij_make_layout_file zsl)" || return 1
  _zellij_write_swarm_layout "${layout_path}" "${pane_count}" "${pane_command}" || {
    command rm -f -- "${layout_path}"
    return 1
  }

  zellij action new-tab --layout "${layout_path}" --cwd "${current_dir}" --name "${tab_name}"
  local exit_code=$?

  command rm -f -- "${layout_path}"
  return "${exit_code}"
}
