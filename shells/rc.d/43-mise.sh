# Ensure command hashing is off for mise.
# shellcheck disable=SC2154
if [[ "${_rc_shell}" == 'bash' ]]; then
  set +h
else
  unsetopt HASH_CMDS
fi

if command -v mise >/dev/null 2>&1; then
  _mise_init=''
  if ! _mise_init="$(mise activate "${_rc_shell}")"; then
    printf 'mise: failed to generate %s activation\n' "${_rc_shell}" >&2
  elif ! eval "${_mise_init}"; then
    printf 'mise: failed to evaluate %s activation\n' "${_rc_shell}" >&2
  fi
  unset _mise_init
fi
