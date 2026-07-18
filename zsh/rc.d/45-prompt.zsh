# Reproduce the Starship prompt with zsh built-ins and jj-git-prompt.

prompt::directory() {
  local root="${PWD}"
  local parent
  local display
  local leading=""
  local -a parts

  while [[ ! -d "${root}/.jj" && ! -e "${root}/.git" ]]; do
    parent="${root:h}"
    if [[ "${parent}" == "${root}" ]]; then
      root=""
      break
    fi
    root="${parent}"
  done

  if [[ -n "${root}" ]]; then
    if [[ "${root}" == "/" ]]; then
      display="${PWD}"
    elif [[ "${PWD}" == "${root}" ]]; then
      display="${root:t}"
    else
      display="${root:t}/${PWD#"${root}/"}"
    fi
  elif [[ "${PWD}" == "${HOME}" ]]; then
    display='~'
  elif [[ "${PWD}" == "${HOME}/"* ]]; then
    display="~/${PWD#"${HOME}/"}"
  else
    display="${PWD}"
  fi

  if [[ "${display}" == /* ]]; then
    leading="/"
    display="${display#/}"
  fi

  parts=("${(@s:/:)display}")
  if (( ${#parts[@]} > 4 )); then
    display="${(j:/:)parts[-4,-1]}"
  else
    display="${leading}${display}"
  fi

  PROMPT_DIRECTORY="${display//\%/%%}"
}

prompt::update() {
  local exit_status=$?
  local hostname=""
  local vcs=""
  local vcs_segment=""
  local directory
  local arrow
  local nonprinting_start='%{'
  local nonprinting_end='%}'

  prompt::directory

  if [[ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]]; then
    hostname="%B%F{green}${HOST%%.*}%f%b "
  fi

  if ! vcs="$("${HOME}/.local/bin/jj-git-prompt" prompt -bash)"; then
    vcs=""
  fi
  vcs="${vcs//\%/%%}"
  vcs="${vcs//$'\001'/${nonprinting_start}}"
  vcs="${vcs//$'\002'/${nonprinting_end}}"
  [[ -z "${vcs}" ]] || vcs_segment="${vcs} "

  directory="%F{blue}${PROMPT_DIRECTORY}%f"
  [[ -w "${PWD}" ]] || directory+="%F{red}🔒%f"

  if (( exit_status == 0 )); then
    arrow='%F{green}➜%f'
  else
    arrow='%F{red}➜%f'
  fi

  PROMPT="${hostname}${vcs_segment}${directory} ${arrow} "
}

if [[ ! -o interactive ]]; then
  return 0
fi

autoload -Uz add-zsh-hook
add-zsh-hook precmd prompt::update
