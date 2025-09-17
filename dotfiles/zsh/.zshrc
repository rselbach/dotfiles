# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
#ZSH_THEME="kiwi" # set by `omz`
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to load
# Setting this variable when ZSH_THEME=random
# cause zsh load theme from this variable instead of
# looking in ~/.oh-my-zsh/themes/
# An empty array have no effect
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

ZSH_TMUX_AUTOSTART="false"
ZSH_TMUX_ITERM2="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  colorize
  tmux
#  zsh-syntax-highlighting
#  zsh-autosuggestions
)

#if [ "$TERM_PROGRAM" != "vscode" ]; then
    # Load Oh My Zsh
source $ZSH/oh-my-zsh.sh
#fi

export GOLANG_PROTOBUF_REGISTRATION_CONFLICT=warn

source $HOME/.kube-ps1/kube-ps1.sh

KUBE_PS1_NS_ENABLE=false

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#

# infinite history
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=$HISTSIZE
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history
#setopt EXTENDED_GLOB             # Extended globs



export PATH=$HOME/bin:$HOME/devel/go/bin:$HOME/go/bin:/usr/local/go/bin:$PATH
DEFAULT_USER="rselbach"


golang_version() {
  setopt localoptions extendedglob

  # If there are Go-specific files in current directory, or current directory is under the GOPATH
  [[ -d Godeps || -f glide.yaml || -n *.go(#qN^/) || -f Gopkg.yml || -f Gopkg.lock || ( $GOPATH && $PWD =~ $GOPATH ) ]] || return

  [ $(command -v go) ] || return

  local go_version=$(go version | awk '{print substr($3, 3)}' )

  echo -n -e "[go${go_version}] "
}

local_prompt() {
  # see if we have a custom prompt icon
  if [[ -f $HOME/.prompt ]]; then
    local prompt_info="$(source $HOME/.prompt)"
  else
    local prompt_info="🤓"
  fi
  echo -n -e "${prompt_info} "
}

local status_color="%(?:%{$fg_bold[green]%}:%{$fg_bold[red]%})"
local ret_status="%{$status_color%}➜ "
if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    xPROMPT='${ret_status}$(local_prompt)$(kube_ps1)[%{$fg[red]%}$USER@%m%{$status_color%}] %{$fg[cyan]%}[%c]%{$reset_color%} $(git_prompt_info)'
else
    xPROMPT='${ret_status}$(local_prompt)$(kube_ps1)%{$fg[cyan]%}[%c]%{$reset_color%} $(git_prompt_info)'
fi

export PATH=/opt/homebrew/bin:$PATH:"/Applications/VMware Fusion.app/Contents/Library"

setopt no_share_history

export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gcloud/application_default_credentials.json

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh



# machine-specific configs
[ -f "${HOME}/.zsh.local" ] && source "${HOME}/.zsh.local"

eval "$(jump shell zsh)"

# cd to git clone root
alias cdr='cd $(git rev-parse --show-toplevel)'


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# try to attach tmux if a session exists, otherwise create a new one
alias tx='tmux attach || tmux new'

#alias vim='nvim'
#alias v='nvim'
export EDITOR=vim
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

printf "\e[?1042l"

eval "$(ssh-agent -s)"

coverhtml() {
  go test -coverprofile=/tmp/c.out "$@" || return -1
  go tool cover -html=/tmp/c.out -o /tmp/coverage.html || return -2
  open /tmp/coverage.html
}

alias rebase="git fetch -va && git rebase origin/main"
alias rb="git fetch -va && git rebase origin/main"

export PATH="${HOME}/bin:${PATH}"

export PATH="/opt/homebrew/sbin:$PATH"

export PATH="$HOME/bin:$PATH"

. "$HOME/.nvm/nvm.sh"

export PATH="$HOME/.govm/current/bin:$PATH"
alias claude-cheap=ANTHROPIC_MODEL="claude-3-5-haiku-20241022" ANTHROPIC_SMALL_FAST_MODEL="claude-3-5-haiku-20241022" claude


[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

if which hcloud > /dev/null; then
  complete -C $(which hcloud) hcloud
fi

export XDG_CONFIG_HOME=~/.config nu

