# cmux 0.64.19 bundles Ghostty's SSH wrapper but has no ghostty executable.
if [[ "${GHOSTTY_BIN_DIR:-}" == */cmux.app/Contents/MacOS \
  && ! -x "${GHOSTTY_BIN_DIR}/ghostty" ]]; then
  _cmux_features=",${GHOSTTY_SHELL_FEATURES:-},"
  while [[ "${_cmux_features}" == *,ssh-env,* ]]; do
    _cmux_features="${_cmux_features/,ssh-env,/,}"
  done
  _cmux_features="${_cmux_features#,}"
  _cmux_features="${_cmux_features%,}"
  export GHOSTTY_SHELL_FEATURES="${_cmux_features}"
  _cmux_remove_ssh_function='true'
  unset _cmux_features
fi
