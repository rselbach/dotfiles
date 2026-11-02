if [[ -f "${HOME}/.atuin/bin/env" ]]; then
  # shellcheck source=/dev/null
  source "${HOME}/.atuin/bin/env" || return
fi
if command -v atuin >/dev/null 2>&1; then
  bash::init atuin init bash --disable-up-arrow || return
fi
