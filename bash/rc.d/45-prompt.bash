# Build prompt text in a variable: directory and branch names are never code.
prompt::directory() {
  local root=${PWD} parent display leading=''
  local -a parts
  while [[ ! -d "${root}/.jj" && ! -e "${root}/.git" ]]; do
    parent=${root%/*}
    [[ -n "${parent}" ]] || parent=/
    if [[ ${parent} == "${root}" ]]; then
      root=''
      break
    fi
    root=${parent}
  done
  if [[ ${root} == / ]]; then
    display=${PWD}
  elif [[ -n ${root} && ${PWD} == "${root}" ]]; then
    display=${root##*/}
  elif [[ -n ${root} ]]; then
    display=${root##*/}/${PWD#"${root}/"}
  elif [[ ${PWD} == "${HOME}" ]]; then
    display='~'
  elif [[ ${PWD} == "${HOME}/"* ]]; then
    # Display a literal home abbreviation.
    # shellcheck disable=SC2088
    display="~/${PWD#"${HOME}/"}"
  else
    display=${PWD}
  fi
  if [[ ${display} == /* ]]; then
    leading=/
    display=${display#/}
  fi
  IFS=/ read -r -a parts <<< "${display}"
  if (( ${#parts[@]} > 4 )); then
    parts=("${parts[@]: -4}")
    local IFS=/
    display=${parts[*]}
  else
    display=${leading}${display}
  fi
  PROMPT_DIRECTORY=${display}
}

prompt::update() {
  local status=$? vcs='' hostname='' arrow
  local blue=$'\001\e[34m\002' green=$'\001\e[32m\002'
  local red=$'\001\e[31m\002' reset=$'\001\e[0m\002'
  prompt::directory
  if [[ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]]; then
    hostname="${green}${HOSTNAME%%.*}${reset} "
  fi
  if command -v jj-git-prompt >/dev/null 2>&1; then
    vcs=$(jj-git-prompt prompt -bash) || vcs=''
    [[ -z ${vcs} ]] || vcs+=' '
  fi
  arrow=${green}
  (( status == 0 )) || arrow=${red}
  _bash_prompt="${hostname}${vcs}${blue}${PROMPT_DIRECTORY}${reset}"
  [[ -w ${PWD} ]] || _bash_prompt+="${red}🔒${reset}"
  _bash_prompt+=" ${arrow}➜${reset} "
  PS1='${_bash_prompt}'
  return "${status}"
}
