if [[ $- == *i* ]]; then
  HISTFILE="${HOME}/.bash_history"
  HISTSIZE=32768
  HISTFILESIZE="${HISTSIZE}"
  # bash-preexec requires commands with leading spaces to remain in history.
  HISTCONTROL='ignoredups:erasedups'

  shopt -s histappend
  shopt -s histverify
  set -H

  history::append() {
    history -a
  }

  _history_hook_found='false'
  for _history_prompt_commands in "${PROMPT_COMMAND[@]:-}"; do
    _history_prompt_commands="${_history_prompt_commands//;/$'\n'}"
    case $'\n'"${_history_prompt_commands}"$'\n' in
      *$'\nhistory::append\n'*)
        _history_hook_found='true'
        break
        ;;
    esac
  done

  if [[ "${_history_hook_found}" == 'false' \
    && -n "${bash_preexec_imported:-}" ]]; then
    precmd_functions+=(history::append)
  elif [[ "${_history_hook_found}" == 'false' ]]; then
    PROMPT_COMMAND="history::append${PROMPT_COMMAND:+;${PROMPT_COMMAND}}"
  fi
  unset _history_hook_found _history_prompt_commands
fi
