# ============================================================================
# Environment Variables
# ============================================================================

# Basic environment settings
set -gx LANG en_US.UTF-8
set -gx EDITOR nvim
set -gx DEFAULT_USER rselbach
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx EZA_CONFIG_DIR "$XDG_CONFIG_HOME/eza"
set -g fish_greeting

# Application-specific variables
set -gx STARSHIP_CONFIG "$XDG_CONFIG_HOME/starship/starship.toml"
set -gx GOLANG_PROTOBUF_REGISTRATION_CONFLICT ignore
set -gx KUBE_PS1_NS_ENABLE false
set -gx GOOGLE_APPLICATION_CREDENTIALS "$HOME/.config/gcloud/application_default_credentials.json"

# ============================================================================
# PATH Configuration (order preserved: later entries take precedence)
# ============================================================================

# Use fish_add_path to avoid duplicates and prepend entries
fish_add_path /usr/local/bin
fish_add_path /usr/local/go/bin
fish_add_path $HOME/go/bin
fish_add_path $HOME/devel/go/bin
fish_add_path $HOME/.govm/current/bin
fish_add_path $HOME/bin
fish_add_path /opt/homebrew/sbin
fish_add_path /opt/homebrew/bin
fish_add_path /home/linuxbrew/.linuxbrew/bin
fish_add_path /home/linuxbrew/.linuxbrew/sbin
fish_add_path "/Applications/VMware Fusion.app/Contents/Library"

# ============================================================================
# Shell Options / History
# ============================================================================

# Notes:
# - Zsh options like CASE_SENSITIVE, DISABLE_UNTRACKED_FILES_DIRTY, and detailed
#   history flags do not have direct Fish equivalents. Fish manages history differently.
# - Bind Ctrl-R to Fish's history pager (interactive search).
bind \cr history-pager

# ============================================================================
# Tool Initialization
# ============================================================================

# Starship prompt
type -q starship; and starship init fish | source

# SSH agent (fixed socket)
set -gx SSH_AUTH_SOCK_FILE "$HOME/.ssh/ssh-agent.sock"

if not set -q SSH_AGENT_PID
    if test -S "$SSH_AUTH_SOCK_FILE"
        set -gx SSH_AUTH_SOCK "$SSH_AUTH_SOCK_FILE"
    else
        # Start agent and parse its output to set env vars
        set -l _agent_out (ssh-agent -s -a "$SSH_AUTH_SOCK_FILE")
        for line in $_agent_out
            if string match -r '^SSH_AUTH_SOCK=' -- $line
                set -gx SSH_AUTH_SOCK (string replace -r '.*=' '' (string replace -r ';.*$' '' $line))
            end
            if string match -r '^SSH_AGENT_PID=' -- $line
                set -gx SSH_AGENT_PID (string replace -r '.*=' '' (string replace -r ';.*$' '' $line))
            end
        end
    end
end

# Zoxide (z command replacement)
type -q zoxide; and zoxide init fish | source

# Python environment (pyenv)
if type -q pyenv
    pyenv init - | source
    pyenv init --path | source
end

# Go private modules
set -gx GOPRIVATE github.com/hashicorp

# ============================================================================
# Source External Files
# ============================================================================

# Kubernetes PS1 (Fish variant if available)
if test -f "$HOME/.kube-ps1/kube-ps1.fish"
    source "$HOME/.kube-ps1/kube-ps1.fish"
end

# FZF (Fish integration if installed)
if test -f "$HOME/.fzf.fish"
    source "$HOME/.fzf.fish"
end

# VS Code shell integration
if test "$TERM_PROGRAM" = "vscode"
    source (code --locate-shell-integration-path fish)
end

# ============================================================================
# Completions
# ============================================================================

# Example (commented as in Zsh). For Fish you'd define completions differently:
# if type -q hcloud
#     # Define fish completions here if desired
# end

# ============================================================================
# Aliases
# ============================================================================

alias tx 'tmux attach; or tmux new'
alias rebase 'git fetch -va; and git rebase origin/main'
alias rb 'git fetch -va; and git rebase origin/main'
alias ls 'eza'
alias cx 'cd'
alias ll 'eza -la'
alias l 'eza -la'
alias pef 'ps -ef'

# ============================================================================
# Functions
# ============================================================================

function coverhtml
    go test -coverprofile=/tmp/c.out $argv; or return -1
    go tool cover -html=/tmp/c.out -o /tmp/coverage.html; or return -2
    open /tmp/coverage.html
end

# ============================================================================
# Machine-specific configurations (keep this last)
# ============================================================================

# Optional local overrides
if test -f "$HOME/.config/fish/config.local.fish"
    source "$HOME/.config/fish/config.local.fish"
end
if test -f "$HOME/.fish.local"
    source "$HOME/.fish.local"
end

# opencode
fish_add_path /Users/rselbach/.opencode/bin

# gpg
set -gx GPG_TTY (tty)

# fnm (Fast Node Manager)
set -gx FNM_PATH "/opt/homebrew/opt/fnm/bin"
if test -d "$FNM_PATH"
    fnm env --use-on-cd | source
end

# Final PATH addition (highest precedence)
fish_add_path /Users/rselbach/.local/bin

