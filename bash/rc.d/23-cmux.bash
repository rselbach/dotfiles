if [[ "${_cmux_remove_ssh_function:-}" == 'true' ]] \
  && declare -F ssh >/dev/null 2>&1; then
  _cmux_ssh_definition=''
  if _cmux_ssh_definition="$(declare -f ssh)" \
    && [[ "${_cmux_ssh_definition}" == \
      *"\$GHOSTTY_BIN_DIR/ghostty"* ]]; then
    unset -f ssh
  fi
  unset _cmux_ssh_definition
fi

unset _cmux_remove_ssh_function
