_zellij_shell_executable="$(command -v zsh)" || return 1
_zellij_shell_flags='-lc'

source "${_rc_dir:?}/../shell/rc.d/55-zellij.sh"
