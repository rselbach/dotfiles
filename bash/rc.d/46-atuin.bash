[[ $- == *i* && -t 0 ]] || return 0

if command -v atuin >/dev/null 2>&1; then
  if [[ -z "${bash_preexec_imported:-}" ]]; then
    bash_preexec_path="${HOMEBREW_PREFIX:-}/etc/profile.d/bash-preexec.sh"
    if [[ ! -r "${bash_preexec_path}" ]]; then
      printf '%s\n' 'atuin: bash-preexec is not installed' >&2
      unset bash_preexec_path
      return 0
    fi

    original_prompt_command="${PROMPT_COMMAND:-}"
    migrate_prompt_hook='false'
    case "${PROMPT_COMMAND:-}" in
      'prompt::update')
        PROMPT_COMMAND=''
        migrate_prompt_hook='true'
        ;;
      'prompt::update;'*)
        PROMPT_COMMAND="${PROMPT_COMMAND#prompt::update;}"
        migrate_prompt_hook='true'
        ;;
    esac

    # shellcheck source=/dev/null
    if ! source "${bash_preexec_path}"; then
      printf '%s\n' 'atuin: failed to load bash-preexec' >&2
      PROMPT_COMMAND="${original_prompt_command}"
      unset bash_preexec_path original_prompt_command migrate_prompt_hook
      return 0
    fi
    unset bash_preexec_path original_prompt_command

    if [[ "${migrate_prompt_hook}" == 'true' ]]; then
      precmd_functions=(prompt::update "${precmd_functions[@]}")
    fi
    unset migrate_prompt_hook
  fi

  if [[ "${__atuin_initialized:-}" != 'true' ]]; then
    if atuin_init_output="$(atuin init bash --disable-up-arrow)"; then
      if ! eval "${atuin_init_output}"; then
        printf '%s\n' 'atuin: failed to evaluate Bash initialization' >&2
      fi
    else
      printf '%s\n' 'atuin: failed to generate Bash initialization' >&2
    fi
    unset atuin_init_output
  fi
fi
