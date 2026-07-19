# Ensure command hashing is off for mise.
set +h

if command -v mise >/dev/null 2>&1; then
  if mise_init_output="$(mise activate bash)"; then
    if ! eval "${mise_init_output}"; then
      printf '%s\n' 'mise: failed to evaluate Bash activation' >&2
    fi
  else
    printf '%s\n' 'mise: failed to generate Bash activation' >&2
  fi
  unset mise_init_output
fi
