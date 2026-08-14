[[ -o interactive ]] || return 0

# Prefer the standalone installer's location, which is not on PATH by default.
[[ -f "${HOME}/.atuin/bin/env" ]] && source "${HOME}/.atuin/bin/env"

if command -v atuin >/dev/null 2>&1; then
  _atuin_init=''
  if ! _atuin_init="$(atuin init zsh --disable-up-arrow)"; then
    printf '%s\n' 'atuin: failed to generate Zsh initialization' >&2
  elif ! eval "${_atuin_init}"; then
    printf '%s\n' 'atuin: failed to evaluate Zsh initialization' >&2
  fi
  unset _atuin_init
fi
