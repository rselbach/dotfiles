# Snapshot Zsh's path for helpers invoked after startup.
_tmux_shell_executable="$(command -v zsh)" || _tmux_shell_executable='zsh'

source "${_rc_dir:?}/../shell/rc.d/54-tmux.sh"
