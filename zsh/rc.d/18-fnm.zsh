_fnm_path=''

if [[ -n "${HOMEBREW_PREFIX:-}" \
  && -x "${HOMEBREW_PREFIX}/opt/fnm/bin/fnm" ]]; then
  _fnm_path="${HOMEBREW_PREFIX}/opt/fnm/bin"
else
  _fnm_candidates=(
    /opt/homebrew/opt/fnm/bin
    /home/linuxbrew/.linuxbrew/opt/fnm/bin
    "${HOME}/.linuxbrew/opt/fnm/bin"
    /usr/local/opt/fnm/bin
  )

  for _fnm_candidate in "${_fnm_candidates[@]}"; do
    if [[ -x "${_fnm_candidate}/fnm" ]]; then
      _fnm_path="${_fnm_candidate}"
      break
    fi
  done
fi

if [[ -n "${_fnm_path}" ]]; then
  _path_add "${_fnm_path}"
  _fnm_executable="${_fnm_path}/fnm"
  _fnm_shell='zsh'

  _fnm_lazy_env() {
    local fnm_env

    if ! fnm_env="$("${_fnm_executable}" env --shell "${_fnm_shell}")"; then
      printf 'fnm: failed to generate %s environment\n' "${_fnm_shell}" >&2
      return 1
    fi
    if ! eval "${fnm_env}"; then
      printf 'fnm: failed to evaluate %s environment\n' "${_fnm_shell}" >&2
      return 1
    fi

    unset -f fnm node npm _fnm_lazy_env
    unset _fnm_executable _fnm_shell
  }

  fnm() {
    local fnm_executable="${_fnm_executable}"

    _fnm_lazy_env || return 1
    "${fnm_executable}" "$@"
  }

  node() {
    _fnm_lazy_env || return 1
    node "$@"
  }

  npm() {
    _fnm_lazy_env || return 1
    npm "$@"
  }
fi

unset _fnm_path _fnm_candidates _fnm_candidate
