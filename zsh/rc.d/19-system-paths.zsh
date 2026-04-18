path+=(
  /usr/local/go/bin
  /usr/local/bin
  /home/linuxbrew/.linuxbrew/bin
  /home/linuxbrew/.linuxbrew/sbin
  "/Applications/VMware Fusion.app/Contents/Library"
  "${_zsh_path_base[@]}"
)

export PATH

unset _zsh_path_base
