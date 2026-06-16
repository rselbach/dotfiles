{
  local _brew_prefix

  if [[ -x /opt/homebrew/bin/brew ]]; then
    _brew_prefix=/opt/homebrew
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    _brew_prefix=/home/linuxbrew/.linuxbrew
  elif [[ -x ~/.linuxbrew/bin/brew ]]; then
    _brew_prefix=~/.linuxbrew
  elif [[ -x /usr/local/bin/brew ]]; then
    _brew_prefix=/usr/local
  fi

  if [[ -n "${_brew_prefix}" ]]; then
    path+=(
      "${_brew_prefix}/bin"
      "${_brew_prefix}/sbin"
    )
    export HOMEBREW_PREFIX="${_brew_prefix}"
  fi
}
