# ============================================================================
# Environment Variables
# ============================================================================

# Basic environment settings
set -gx LANG en_US.UTF-8
set -gx EDITOR nvim
set -gx DEFAULT_USER rselbach
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx EZA_CONFIG_DIR "$XDG_CONFIG_HOME/eza"
set -g fish_greeting ""

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
fish_add_path --move $HOME/bin

# Platform-specific paths
switch (uname)
    case Darwin
        fish_add_path /opt/homebrew/sbin
        fish_add_path /opt/homebrew/bin
        test -d "/Applications/VMware Fusion.app"; and fish_add_path "/Applications/VMware Fusion.app/Contents/Library"
    case Linux
        test -d /home/linuxbrew/.linuxbrew; and fish_add_path /home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/sbin
end

# ============================================================================
# Shell Options / History
# ============================================================================

# Notes:
# - Zsh options like CASE_SENSITIVE, DISABLE_UNTRACKED_FILES_DIRTY, and detailed
#   history flags do not have direct Fish equivalents. Fish manages history differently.
# - Bind Ctrl-R to Fish's history pager (interactive search).
if status is-interactive
    bind \cr history-pager
end

# ============================================================================
# Tool Initialization
# ============================================================================

# Starship prompt
type -q starship; and starship init fish | source

# SSH agent (fixed socket)
set -gx SSH_AUTH_SOCK_FILE "$HOME/.ssh/ssh-agent.sock"

# check if agent is reachable via existing socket
if test -S "$SSH_AUTH_SOCK_FILE"
    set -gx SSH_AUTH_SOCK "$SSH_AUTH_SOCK_FILE"
    # verify agent is actually responding
    if not ssh-add -l >/dev/null 2>&1; and test $status -ne 1
        # status 1 = agent running but no keys; other = agent dead
        rm -f "$SSH_AUTH_SOCK_FILE"
        set -e SSH_AUTH_SOCK
    end
end

# start new agent if needed
if not test -S "$SSH_AUTH_SOCK_FILE"
    set -l _agent_out (ssh-agent -s -a "$SSH_AUTH_SOCK_FILE" 2>/dev/null)
    for line in $_agent_out
        if string match -q -r '^SSH_AUTH_SOCK=' -- $line
            set -gx SSH_AUTH_SOCK (string replace -r '.*=' '' (string replace -r ';.*$' '' $line))
        end
        if string match -q -r '^SSH_AGENT_PID=' -- $line
            set -gx SSH_AGENT_PID (string replace -r '.*=' '' (string replace -r ';.*$' '' $line))
        end
    end
end

# Zoxide (z command replacement)
type -q zoxide; and zoxide init fish | source

# Python environment (pyenv) - only init on login shells for speed
if type -q pyenv; and status is-login
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
if test "$TERM_PROGRAM" = vscode
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
# Abbreviations (expand inline for better history/composability)
# ============================================================================

if status is-interactive
    abbr --add tx 'tmux attach; or tmux new'
    abbr --add rebase 'git fetch -va && git rebase origin/main'
    abbr --add rb 'git fetch -va && git rebase origin/main'
    abbr --add cx cd
    abbr --add pef 'ps -ef'
end

# Keep as aliases (these benefit from being actual commands)
alias ls eza
alias ll 'eza -la'
alias l 'eza -la'

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
fish_add_path $HOME/.opencode/bin

# gpg
set -gx GPG_TTY (tty)

# fnm (Fast Node Manager) - only init on login shells for speed
set -gx FNM_PATH /opt/homebrew/opt/fnm/bin
if test -d "$FNM_PATH"; and status is-login
    fnm env --use-on-cd | source
end

# Final PATH addition (highest precedence)
fish_add_path --move $HOME/.local/bin
