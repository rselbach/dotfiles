_brew_prefix=''

if [[ -x /opt/homebrew/bin/brew ]]; then
  _brew_prefix='/opt/homebrew'
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  _brew_prefix='/home/linuxbrew/.linuxbrew'
elif [[ -x "${HOME}/.linuxbrew/bin/brew" ]]; then
  _brew_prefix="${HOME}/.linuxbrew"
elif [[ -x /usr/local/bin/brew ]]; then
  _brew_prefix='/usr/local'
fi

if [[ -n "${_brew_prefix}" ]]; then
  _bash_path+=(
    "${_brew_prefix}/bin"
    "${_brew_prefix}/sbin"
  )
  export HOMEBREW_PREFIX="${_brew_prefix}"
fi

unset _brew_prefix
