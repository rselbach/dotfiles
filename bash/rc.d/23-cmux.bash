# cmux 0.64.19 bundles Ghostty's SSH wrapper but has no ghostty executable.
if [[ "${GHOSTTY_BIN_DIR:-}" == */cmux.app/Contents/MacOS \
  && ! -x "${GHOSTTY_BIN_DIR}/ghostty" ]]; then
  _cmux_shell_features=()
  IFS=',' read -r -a _cmux_shell_features \
    <<< "${GHOSTTY_SHELL_FEATURES:-}"
  _cmux_filtered_features=()

  for _cmux_shell_feature in "${_cmux_shell_features[@]}"; do
    if [[ -n "${_cmux_shell_feature}" \
      && "${_cmux_shell_feature}" != 'ssh-env' ]]; then
      _cmux_filtered_features+=("${_cmux_shell_feature}")
    fi
  done

  GHOSTTY_SHELL_FEATURES=''
  for _cmux_shell_feature in "${_cmux_filtered_features[@]}"; do
    if [[ -n "${GHOSTTY_SHELL_FEATURES}" ]]; then
      GHOSTTY_SHELL_FEATURES+=','
    fi
    GHOSTTY_SHELL_FEATURES+="${_cmux_shell_feature}"
  done
  export GHOSTTY_SHELL_FEATURES

  if declare -F ssh >/dev/null 2>&1; then
    _cmux_ssh_definition=''
    if _cmux_ssh_definition="$(declare -f ssh)" \
      && [[ "${_cmux_ssh_definition}" == \
        *"\$GHOSTTY_BIN_DIR/ghostty"* ]]; then
      unset -f ssh
    fi
  fi

  unset _cmux_shell_features _cmux_filtered_features
  unset _cmux_shell_feature _cmux_ssh_definition
fi
