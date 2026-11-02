_zellij_shell_executable="$(command -v bash)" || return 1
_zellij_shell_flags='-lic'

# shellcheck source=shell/rc.d/55-zellij.sh
source "${_bashrc_dir:?}/../shell/rc.d/55-zellij.sh"
