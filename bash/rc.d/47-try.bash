if command -v try >/dev/null 2>&1; then
  # $SHELL still names the login shell during a Bash experiment.
  SHELL=${BASH} bash::init command try init "${HOME}/Work/tries" || return
fi
