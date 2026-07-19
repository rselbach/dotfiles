if [[ $- == *i* ]]; then
  shopt -s progcomp

  if [[ -n "${HOMEBREW_PREFIX:-}" \
    && -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
    if (( BASH_VERSINFO[0] < 4 )); then
      # Homebrew's Carapace completion uses Bash 4-only options.
      complete() {
        case " $* " in
          *' -o noquote '*) return 0 ;;
          *) builtin complete "$@" ;;
        esac
      }
    fi
    # shellcheck source=/dev/null
    source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
    if (( BASH_VERSINFO[0] < 4 )); then
      unset -f complete
    fi
  elif [[ -r /etc/bash_completion ]]; then
    # shellcheck source=/dev/null
    source /etc/bash_completion
  fi

  bind '"\C-i": complete'
  bind 'set completion-ignore-case on'
fi
