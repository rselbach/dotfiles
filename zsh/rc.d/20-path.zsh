typeset -U path PATH

path=(
  "${HOME}/.local/bin"
  "${OMARCHY_PATH}/bin"
  "${HOME}/.opencode/bin"
  "${HOME}/.govm/current/bin"
  "${HOME}/devel/go/bin"
  "${HOME}/go/bin"
  "${HOME}/bin"
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /opt/homebrew/opt/fnm/bin
  /usr/local/go/bin
  /usr/local/bin
  /home/linuxbrew/.linuxbrew/bin
  /home/linuxbrew/.linuxbrew/sbin
  "/Applications/VMware Fusion.app/Contents/Library"
  "${path[@]}"
)

export PATH
