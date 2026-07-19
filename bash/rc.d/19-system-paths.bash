# _bash_path_base is populated by 11-core-path.bash.
# shellcheck disable=SC2154
_bash_path+=(
  /usr/local/go/bin
  /usr/local/bin
  /home/linuxbrew/.linuxbrew/bin
  /home/linuxbrew/.linuxbrew/sbin
  "/Applications/VMware Fusion.app/Contents/Library"
  "${_bash_path_base[@]}"
)

_bash_path_unique=()
for _bash_path_entry in "${_bash_path[@]}"; do
  _bash_path_seen='false'
  for _bash_path_existing in "${_bash_path_unique[@]}"; do
    if [[ "${_bash_path_entry}" == "${_bash_path_existing}" ]]; then
      _bash_path_seen='true'
      break
    fi
  done

  if [[ "${_bash_path_seen}" == 'false' ]]; then
    _bash_path_unique+=("${_bash_path_entry}")
  fi
done

# shellcheck disable=SC2123
PATH=''
_bash_path_index=0
for _bash_path_entry in "${_bash_path_unique[@]}"; do
  if (( _bash_path_index == 0 )); then
    PATH="${_bash_path_entry}"
  else
    PATH="${PATH}:${_bash_path_entry}"
  fi
  ((_bash_path_index += 1))
done
export PATH

unset -f _path_add
unset _bash_path_base _bash_path _bash_path_unique
unset _bash_path_entry _bash_path_existing _bash_path_seen _bash_path_index
