if [[ $- == *i* ]]; then
  set -o emacs

  bind '"\e[H": beginning-of-line'
  bind '"\eOH": beginning-of-line'
  bind '"\e[1~": beginning-of-line'
  bind '"\e[F": end-of-line'
  bind '"\eOF": end-of-line'
  bind '"\e[4~": end-of-line'
  bind '"\e[2~": overwrite-mode'
  bind '"\e[3~": delete-char'
  bind '"\e[A": previous-history'
  bind '"\e[B": next-history'
  bind '"\e[D": backward-char'
  bind '"\e[C": forward-char'
  bind '"\e[5~": beginning-of-history'
  bind '"\e[6~": end-of-history'
  bind '"\C-?": backward-delete-char'
  bind '"\C-h": backward-delete-char'
  bind '"\e[Z": menu-complete-backward'

  bind '"\e[1;5D": backward-word'
  bind '"\e[1;5C": forward-word'
fi
