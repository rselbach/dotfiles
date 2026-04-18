export LANG='en_US.UTF-8'
export EDITOR='nvim'
export DEFAULT_USER='rselbach'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export EZA_CONFIG_DIR="${XDG_CONFIG_HOME}/eza"
export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"
export GOLANG_PROTOBUF_REGISTRATION_CONFLICT='ignore'
export KUBE_PS1_NS_ENABLE=false
export GOOGLE_APPLICATION_CREDENTIALS="${XDG_CONFIG_HOME}/gcloud/application_default_credentials.json"
export GOPRIVATE='github.com/hashicorp'
export SUDO_EDITOR="${SUDO_EDITOR:-$EDITOR}"
export BAT_THEME='ansi'
export OMARCHY_PATH="${OMARCHY_PATH:-$HOME/.local/share/omarchy}"

# Tokyo Night FZF colors.
export FZF_DEFAULT_OPTS=" \
--color=bg+:#283457,bg:#1a1b26,spinner:#ff007c,hl:#2ac3de \
--color=fg:#c0caf5,header:#ff9e64,info:#545c7e,pointer:#ff007c \
--color=marker:#ff007c,fg+:#c0caf5,prompt:#2ac3de,hl+:#2ac3de \
--color=selected-bg:#283457"

if [[ -o interactive ]]; then
  export GPG_TTY="$(tty)"
fi
