shopt -s autocd cdspell dotglob checkwinsize histappend cmdhist histverify
set -o emacs
# mise changes executable locations as directories change.
set +h
HISTFILE="${HOME}/.bash_history"
HISTSIZE=32768
HISTFILESIZE=32768
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T '

bash::history() {
  local status=$?
  history -a
  # Do not import other terminals' history (matching Zsh's no_share_history).
  return "${status}"
}

bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'
bind '"\e[Z": menu-complete-backward'
bind '"\e[1;5D": backward-word'
bind '"\e[1;5C": forward-word'
bind '"\e[H": beginning-of-line'
bind '"\e[F": end-of-line'
bind '"\eOH": beginning-of-line'
bind '"\eOF": end-of-line'
bind '"\e[2~": overwrite-mode'
bind '"\e[3~": delete-char'
bind '"\e[5~": beginning-of-history'
bind '"\e[6~": end-of-history'
