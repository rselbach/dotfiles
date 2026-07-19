if [[ "${_cmux_remove_ssh_function:-}" == 'true' ]] \
  && (( $+functions[ssh] )) \
  && [[ "${functions[ssh]}" == *'$GHOSTTY_BIN_DIR/ghostty'* ]]; then
  unfunction ssh
fi

unset _cmux_remove_ssh_function
