mup() {
  MISE_MINIMUM_RELEASE_AGE=0 mise up "$@"
}

pyenv() {
  local executable
  executable=$(type -P pyenv) || {
    printf '%s\n' 'pyenv: command not found' >&2
    return 127
  }
  bash::init "${executable}" init - bash || return
  # pyenv init normally replaces this function; avoid recursion if it does not.
  if [[ $(declare -f pyenv) == *'bash::init'* ]]; then
    unset -f pyenv
  fi
  pyenv "$@"
}

if command -v rbenv >/dev/null 2>&1; then
  bash::init rbenv init - bash || return
fi
if command -v mise >/dev/null 2>&1; then
  bash::init mise activate bash || return
fi
