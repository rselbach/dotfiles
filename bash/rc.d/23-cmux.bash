# cmux bundles Ghostty integration without a ghostty executable.
if [[ ${GHOSTTY_BIN_DIR:-} == */cmux.app/Contents/MacOS \
  && ! -x "${GHOSTTY_BIN_DIR}/ghostty" ]]; then
  _cmux_features=,${GHOSTTY_SHELL_FEATURES:-},
  while [[ ${_cmux_features} == *,ssh-env,* ]]; do
    _cmux_features=${_cmux_features/,ssh-env,/,}
  done
  _cmux_features=${_cmux_features#,}
  export GHOSTTY_SHELL_FEATURES=${_cmux_features%,}
  # Match the literal variable reference in Ghostty's function body.
  # shellcheck disable=SC2016
  if declare -F ssh >/dev/null \
    && [[ $(declare -f ssh) == *'$GHOSTTY_BIN_DIR/ghostty'* ]]; then
    unset -f ssh
  fi
  unset _cmux_features
fi
