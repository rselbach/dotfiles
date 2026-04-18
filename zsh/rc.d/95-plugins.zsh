if [[ ! -o interactive ]]; then
  return 0
fi

_plugins_dir="${${(%):-%N}:A:h:h}/vendor"

[[ -f "${_plugins_dir}/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "${_plugins_dir}/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "${_plugins_dir}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "${_plugins_dir}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

unset _plugins_dir
