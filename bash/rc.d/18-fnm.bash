_fnm_path=''

if [[ -n "${HOMEBREW_PREFIX:-}" \
  && -d "${HOMEBREW_PREFIX}/opt/fnm/bin" ]]; then
  _fnm_path="${HOMEBREW_PREFIX}/opt/fnm/bin"
else
  _fnm_candidates=(
    /opt/homebrew/opt/fnm/bin
    /home/linuxbrew/.linuxbrew/opt/fnm/bin
    "${HOME}/.linuxbrew/opt/fnm/bin"
    /usr/local/opt/fnm/bin
  )

  for _fnm_candidate in "${_fnm_candidates[@]}"; do
    if [[ -d "${_fnm_candidate}" ]]; then
      _fnm_path="${_fnm_candidate}"
      break
    fi
  done
fi

if [[ -z "${_fnm_path}" ]]; then
  for _fnm_candidate in "${_bash_path[@]}"; do
    if [[ -x "${_fnm_candidate}/fnm" ]]; then
      _fnm_path="${_fnm_candidate}"
      break
    fi
  done
fi

if [[ -n "${_fnm_path}" ]]; then
  _bash_path+=("${_fnm_path}")

  _fnm_lazy_env() {
    local fnm_env

    unset -f fnm node npm _fnm_lazy_env
    if ! fnm_env="$(command fnm env)"; then
      return 1
    fi

    eval "${fnm_env}"
  }

  fnm() {
    _fnm_lazy_env || return
    fnm "$@"
  }

  node() {
    _fnm_lazy_env || return
    node "$@"
  }

  npm() {
    _fnm_lazy_env || return
    npm "$@"
  }
fi

unset _fnm_path _fnm_candidates _fnm_candidate
