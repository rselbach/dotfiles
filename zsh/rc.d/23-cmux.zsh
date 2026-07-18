# cmux 0.64.19 bundles Ghostty's SSH wrapper but has no ghostty executable.
if [[ "${GHOSTTY_BIN_DIR:-}" == */cmux.app/Contents/MacOS \
  && ! -x "${GHOSTTY_BIN_DIR}/ghostty" ]]; then
  typeset -a _cmux_shell_features
  _cmux_shell_features=("${(@s:,:)GHOSTTY_SHELL_FEATURES:-}")
  _cmux_shell_features=("${(@)_cmux_shell_features:#ssh-env}")
  export GHOSTTY_SHELL_FEATURES="${(j:,:)_cmux_shell_features}"
  unset _cmux_shell_features

  if (( $+functions[ssh] )) \
    && [[ "${functions[ssh]}" == *'$GHOSTTY_BIN_DIR/ghostty'* ]]; then
    unfunction ssh
  fi
fi
