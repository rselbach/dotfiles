path+=("/opt/homebrew/opt/fnm/bin")

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
