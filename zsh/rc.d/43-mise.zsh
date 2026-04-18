# Ensure command hashing is off for mise.
unsetopt HASH_CMDS

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi
