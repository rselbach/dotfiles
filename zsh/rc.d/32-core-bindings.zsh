if [[ ! -o interactive ]]; then
  return 0
fi

# Use emacs keymap as the base (Ctrl-A, Ctrl-E, etc.).
bindkey -e

# Bind special keys via terminfo so they work across terminals.
typeset -gA key
key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Backspace]="${terminfo[kbs]}"
key[ShiftTab]="${terminfo[kcbt]}"

[[ -n "${key[Home]}" ]] && bindkey "${key[Home]}" beginning-of-line
[[ -n "${key[End]}" ]] && bindkey "${key[End]}" end-of-line
[[ -n "${key[Insert]}" ]] && bindkey "${key[Insert]}" overwrite-mode
[[ -n "${key[Delete]}" ]] && bindkey "${key[Delete]}" delete-char
[[ -n "${key[Up]}" ]] && bindkey "${key[Up]}" up-line-or-history
[[ -n "${key[Down]}" ]] && bindkey "${key[Down]}" down-line-or-history
[[ -n "${key[Left]}" ]] && bindkey "${key[Left]}" backward-char
[[ -n "${key[Right]}" ]] && bindkey "${key[Right]}" forward-char
[[ -n "${key[PageUp]}" ]] && bindkey "${key[PageUp]}" beginning-of-buffer-or-history
[[ -n "${key[PageDown]}" ]] && bindkey "${key[PageDown]}" end-of-buffer-or-history
[[ -n "${key[Backspace]}" ]] && bindkey "${key[Backspace]}" backward-delete-char
[[ -n "${key[ShiftTab]}" ]] && bindkey "${key[ShiftTab]}" reverse-menu-complete

# Ctrl-Left/Right to jump words.
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Keep the terminal in application mode while zle is active so terminfo stays valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
  zle-line-init() { echoti smkx }
  zle-line-finish() { echoti rmkx }
  zle -N zle-line-init
  zle -N zle-line-finish
fi
