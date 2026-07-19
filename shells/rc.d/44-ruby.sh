if command -v rbenv >/dev/null 2>&1; then
  _rbenv_init=''
  # shellcheck disable=SC2154
  if ! _rbenv_init="$(rbenv init - "${_rc_shell}")"; then
    printf 'rbenv: failed to generate %s initialization\n' \
      "${_rc_shell}" >&2
  else
    _rbenv_path_before="${PATH}"
    _rbenv_shims="${RBENV_ROOT:-${HOME}/.rbenv}/shims"
    PATH=":${PATH}:"
    while [[ "${PATH}" == *":${_rbenv_shims}:"* ]]; do
      PATH="${PATH/:${_rbenv_shims}:/:}"
    done
    PATH="${PATH#:}"
    PATH="${PATH%:}"
    export PATH

    if ! eval "${_rbenv_init}"; then
      PATH="${_rbenv_path_before}"
      export PATH
      printf 'rbenv: failed to evaluate %s initialization\n' \
        "${_rc_shell}" >&2
    fi
    unset _rbenv_path_before _rbenv_shims
  fi
  unset _rbenv_init
fi
