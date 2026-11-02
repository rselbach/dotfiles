if ! declare -F _init_completion >/dev/null; then
  for _completion in \
    "${HOMEBREW_PREFIX:-/nonexistent}/etc/profile.d/bash_completion.sh" \
    /usr/share/bash-completion/bash_completion \
    /etc/bash_completion; do
    if [[ -r "${_completion}" ]]; then
      # shellcheck source=/dev/null
      source "${_completion}" || return
      break
    fi
  done
  unset _completion
fi

if command -v carapace >/dev/null 2>&1; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  bash::init carapace _carapace bash || return
fi

if [[ -r "${OMARCHY_PATH:-}/default/bash/completions" ]]; then
  # shellcheck source=/dev/null
  source "${OMARCHY_PATH}/default/bash/completions" || return
fi
