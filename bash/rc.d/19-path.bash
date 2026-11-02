_path_add "${BUN_INSTALL}/bin" "${HOME}/.opencode/bin" "${HOME}/.hunk/bin"
_path_add /usr/local/go/bin /usr/local/bin
if [[ ${OSTYPE} == darwin* ]]; then
  _path_add '/Applications/VMware Fusion.app/Contents/Library'
fi
# Set by 10-environment.bash.
# shellcheck disable=SC2154
IFS=: read -r -a _bash_path_entries <<< "${_bash_path_base}"
_path_add "${_bash_path_entries[@]}"
export PATH
unset _bash_path_base _bash_path_entries
unset -f _path_add
