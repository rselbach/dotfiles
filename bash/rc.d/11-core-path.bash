declare -a _bash_path_base _bash_path

IFS=':' read -r -a _bash_path_base <<< "${PATH:-}"
_bash_path=()
# PATH is intentionally rebuilt by fragments 12 through 19.
# shellcheck disable=SC2123
PATH=''

_path_add() {
  local path_entry

  for path_entry in "$@"; do
    [[ -n "${path_entry}" ]] || continue
    _bash_path+=("${path_entry}")
  done
}
