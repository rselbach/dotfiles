# ============================================================================
# Environment Variables
# ============================================================================

# Basic environment settings
set -gx LANG en_US.UTF-8
set -gx EDITOR nvim
set -gx VISUAL $EDITOR
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

# Atuin for history sync (replaces default Ctrl-R)
if status is-interactive; and type -q atuin
    set -l cache "$HOME/.cache/fish/atuin.fish"
    if not test -f $cache
        mkdir -p (dirname $cache)
        atuin init fish > $cache
    end
    source $cache
end

# ============================================================================
# Tool Initialization
# ============================================================================

# Starship prompt (cached for speed)
if type -q starship
    set -l cache "$HOME/.cache/fish/starship.fish"
    if not test -f $cache; or test -f $STARSHIP_CONFIG -a (path mtime $STARSHIP_CONFIG) -gt (path mtime $cache)
        mkdir -p (dirname $cache)
        starship init fish > $cache
    end
    source $cache
end

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
        if string match -rq '^SSH_AUTH_SOCK=([^;]+)' -- $line
            set -gx SSH_AUTH_SOCK $match[1]
        else if string match -rq '^SSH_AGENT_PID=([^;]+)' -- $line
            set -gx SSH_AGENT_PID $match[1]
        end
    end
end

# auto-add default SSH key if not loaded
if test -S "$SSH_AUTH_SOCK"
    if not ssh-add -l 2>/dev/null | string match -q '*id_ed25519*' '*id_rsa*'
        for key in ~/.ssh/id_ed25519 ~/.ssh/id_rsa
            test -f $key; and ssh-add $key 2>/dev/null; and break
        end
    end
end

# Zoxide (z command replacement, cached)
if type -q zoxide
    set -l cache "$HOME/.cache/fish/zoxide.fish"
    if not test -f $cache
        mkdir -p (dirname $cache)
        zoxide init fish > $cache
    end
    source $cache
end

# Python environment (pyenv) - lazy loaded on first python/pip call
if type -q pyenv; and not functions -q __pyenv_initialized
    function python --wraps python
        pyenv init - | source
        function __pyenv_initialized; end
        functions -e python pip python3 pip3
        command python $argv
    end
    function python3 --wraps python3
        pyenv init - | source
        function __pyenv_initialized; end
        functions -e python pip python3 pip3
        command python3 $argv
    end
    function pip --wraps pip
        pyenv init - | source
        function __pyenv_initialized; end
        functions -e python pip python3 pip3
        command pip $argv
    end
    function pip3 --wraps pip3
        pyenv init - | source
        function __pyenv_initialized; end
        functions -e python pip python3 pip3
        command pip3 $argv
    end
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
if test "$TERM_PROGRAM" = vscode; and type -q code
    set -l _vscode_integration (code --locate-shell-integration-path fish 2>/dev/null)
    test -n "$_vscode_integration"; and source $_vscode_integration
end

# ============================================================================
# Completions
# ============================================================================

# Carapace for multi-command completions (cached)
if status is-interactive; and type -q carapace
    set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
    set -l cache "$HOME/.cache/fish/carapace.fish"
    if not test -f $cache
        mkdir -p (dirname $cache)
        carapace _carapace fish > $cache
    end
    source $cache
end

# ============================================================================
# Abbreviations (expand inline for better history/composability)
# ============================================================================

if status is-interactive
    abbr --add tx 'tmux attach; or tmux new'
    abbr --add rebase 'git fetch -va && git rebase origin/main'
    abbr --add pef 'ps -ef'
    abbr --add vi nvim
    abbr --add vim nvim
    # eza for better ls
    abbr --add ls eza
    abbr --add ll 'eza -la'
    abbr --add l 'eza -la'
    # git shortcuts
    abbr --add gs 'git status'
    abbr --add gd 'git diff'
    abbr --add gp 'git push'
    abbr --add gl 'git log --oneline -20'
    abbr --add gc 'git commit'
    abbr --add ga 'git add'
    abbr --add gaa 'git add -A'
end

# ============================================================================
# Additional Tools
# ============================================================================

# opencode
fish_add_path $HOME/.opencode/bin

# gpg
set -gx GPG_TTY (tty)

# Gruvbox Light Hard FZF colors
set -gx FZF_DEFAULT_OPTS "\
--color=bg+:#ebdbb2,bg:#f9f5d7,spinner:#d65d0e,hl:#cc241d \
--color=fg:#282828,header:#cc241d,info:#8f3f71,pointer:#d65d0e \
--color=marker:#8f3f71,fg+:#282828,prompt:#8f3f71,hl+:#cc241d \
--color=selected-bg:#d5c4a1"

# bat theme
set -gx BAT_THEME "gruvbox-light"

# fnm (Fast Node Manager) - lazy loaded on first node/npm/npx call
if type -q fnm; and not functions -q __fnm_initialized
    function node --wraps node
        fnm env --use-on-cd | source
        function __fnm_initialized; end
        functions -e node npm npx
        command node $argv
    end
    function npm --wraps npm
        fnm env --use-on-cd | source
        function __fnm_initialized; end
        functions -e node npm npx
        command npm $argv
    end
    function npx --wraps npx
        fnm env --use-on-cd | source
        function __fnm_initialized; end
        functions -e node npm npx
        command npx $argv
    end
end

# Final PATH addition (highest precedence)
fish_add_path --move $HOME/.local/bin

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
