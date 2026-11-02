export LANG='en_US.UTF-8'
export EDITOR='nvim'
export DEFAULT_USER='rselbach'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export SUDO_EDITOR="${SUDO_EDITOR:-${EDITOR}}"
export BAT_THEME='ansi'
export BUN_INSTALL="${HOME}/.bun"

# Keep the first occurrence, like Zsh's unique path array.
_path_add() {
  local entry
  for entry in "$@"; do
    [[ -n "${entry}" ]] || continue
    case ":${PATH}:" in
      *":${entry}:"*) ;;
      *) PATH="${PATH:+${PATH}:}${entry}" ;;
    esac
  done
}

# Capture output before sourcing it so generator failures are not hidden.
bash::init() {
  local init
  init=$("$@") || {
    printf '%s: failed to generate Bash initialization\n' "$1" >&2
    return 1
  }
  # shellcheck source=/dev/null
  source <(printf '%s\n' "${init}")
}

_bash_path_base=${PATH}
# Rebuild PATH deliberately, preserving inherited entries below.
# shellcheck disable=SC2123
PATH=''
_path_add "${HOME}/.local/bin"
if [[ -n "${OMARCHY_PATH:-}" && -d "${OMARCHY_PATH}/bin" ]]; then
  _path_add "${OMARCHY_PATH}/bin"
fi
