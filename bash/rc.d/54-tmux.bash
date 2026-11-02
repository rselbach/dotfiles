# Snapshot Bash's path for helpers invoked after startup.
_tmux_shell_executable="$(command -v bash)" || _tmux_shell_executable='bash'

# shellcheck source=shell/rc.d/54-tmux.sh
source "${_bashrc_dir:?}/../shell/rc.d/54-tmux.sh"
