{
  local _fnm_path

  if [[ -n "${HOMEBREW_PREFIX:-}" && -d "${HOMEBREW_PREFIX}/opt/fnm/bin" ]]; then
    _fnm_path="${HOMEBREW_PREFIX}/opt/fnm/bin"
  else
    local -a _fnm_candidates=(
      /opt/homebrew/opt/fnm/bin
      /home/linuxbrew/.linuxbrew/opt/fnm/bin
      ~/.linuxbrew/opt/fnm/bin
      /usr/local/opt/fnm/bin
    )
    local p
    for p in "${_fnm_candidates[@]}"; do
      if [[ -d "${p}" ]]; then
        _fnm_path="${p}"
        break
      fi
    done
    unset _fnm_candidates p
  fi

  if [[ -n "${_fnm_path}" ]]; then
    path+=("${_fnm_path}")
  fi
}

if command -v fnm >/dev/null 2>&1; then
  _fnm_lazy_env() {
    unset -f fnm node npm _fnm_lazy_env
    eval "$(command fnm env)"
  }

  fnm() {
    _fnm_lazy_env
    fnm "$@"
  }

  node() {
    _fnm_lazy_env
    node "$@"
  }

  npm() {
    _fnm_lazy_env
    npm "$@"
  }
fi
