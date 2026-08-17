# Lazy-load pyenv so startup stays fast.
_pyenv_shell='zsh'

pyenv() {
  local pyenv_executable
  local pyenv_init_output

  pyenv_executable="$(whence -p pyenv)"

  if [[ -z "${pyenv_executable}" ]]; then
    printf '%s\n' 'pyenv: command not found' >&2
    return 127
  fi

  pyenv_init_output="$(
    "${pyenv_executable}" init - "${_pyenv_shell}"
  )" || {
    printf 'pyenv: failed to generate %s initialization\n' \
      "${_pyenv_shell}" >&2
    return 1
  }
  if ! eval "${pyenv_init_output}"; then
    printf 'pyenv: failed to evaluate %s initialization\n' \
      "${_pyenv_shell}" >&2
    return 1
  fi

  unset _pyenv_shell
  pyenv "$@"
}
