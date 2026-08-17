# Ensure command hashing is off for mise.
unsetopt HASH_CMDS

if command -v mise >/dev/null 2>&1; then
  _mise_init=''
  if ! _mise_init="$(mise activate zsh)"; then
    printf '%s\n' 'mise: failed to generate Zsh activation' >&2
  elif ! eval "${_mise_init}"; then
    printf '%s\n' 'mise: failed to evaluate Zsh activation' >&2
  fi
  unset _mise_init
fi
