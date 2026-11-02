# Prepend after integrations have registered their hooks. Preserve the status
# for mise, Atuin, terminal integration, and any existing PROMPT_COMMAND.
_bash_prompt_hooks=()
for _bash_prompt_hook in "${PROMPT_COMMAND[@]}"; do
  case "${_bash_prompt_hook}" in
    'prompt::update'|'bash::history'|'') ;;
    *) _bash_prompt_hooks+=("${_bash_prompt_hook}") ;;
  esac
done
PROMPT_COMMAND=('prompt::update' 'bash::history' "${_bash_prompt_hooks[@]}")
unset _bash_prompt_hooks _bash_prompt_hook
