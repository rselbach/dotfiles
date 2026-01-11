# Dotfiles symlink manager

dotfiles := justfile_directory()

# Directories with special install logic (not just ~/.config symlinks)
special := "claude codex zsh nushell git fish gnupg jj scripts"

# Auto-detect config directories (excluding dot dirs and special cases)
config_dirs := `find . -maxdepth 1 -type d ! -name '.*' \
    ! -name 'claude' ! -name 'codex' ! -name 'zsh' ! -name 'nushell' \
    ! -name 'git' ! -name 'fish' ! -name 'gnupg' \
    ! -name 'jj' ! -name 'scripts' \
    -exec basename {} \; | sort | tr '\n' ' '`

default:
    @just --list

# Install all symlinks
install: install-config install-special

# Install config directories to ~/.config/
install-config:
    #!/usr/bin/env bash
    set -euo pipefail
    backup() { [[ -e "$1" && ! -L "$1" ]] && mv "$1" "$1-old" && echo "⚠ moved $1 → $1-old"; true; }
    mkdir -p ~/.config
    for dir in {{config_dirs}}; do
        backup "$HOME/.config/$dir"
        ln -sfn "{{dotfiles}}/$dir" "$HOME/.config/$dir"
        echo "✓ $dir → ~/.config/$dir"
    done

# Install special cases
install-special: _zsh _claude _codex _nushell _gnupg _jj _git _fish

[private]
_zsh:
    #!/usr/bin/env bash
    set -euo pipefail
    backup() { [[ -e "$1" && ! -L "$1" ]] && mv "$1" "$1-old" && echo "⚠ moved $1 → $1-old"; true; }
    [[ -d "{{dotfiles}}/zsh" ]] || exit 0
    backup "$HOME/.zshrc"
    ln -sfn "{{dotfiles}}/zsh/zshrc" "$HOME/.zshrc"
    echo "✓ zshrc → ~/.zshrc"

[private]
_claude:
    #!/usr/bin/env bash
    set -euo pipefail
    backup() { [[ -e "$1" && ! -L "$1" ]] && mv "$1" "$1-old" && echo "⚠ moved $1 → $1-old"; true; }
    [[ -d "{{dotfiles}}/claude" ]] || exit 0
    backup "$HOME/.claude"
    ln -sfn "{{dotfiles}}/claude" "$HOME/.claude"
    echo "✓ claude → ~/.claude"

[private]
_codex:
    #!/usr/bin/env bash
    set -euo pipefail
    backup() { [[ -e "$1" && ! -L "$1" ]] && mv "$1" "$1-old" && echo "⚠ moved $1 → $1-old"; true; }
    [[ -d "{{dotfiles}}/codex" ]] || exit 0
    backup "$HOME/.codex"
    ln -sfn "{{dotfiles}}/codex" "$HOME/.codex"
    echo "✓ codex → ~/.codex"

[private]
_nushell:
    #!/usr/bin/env bash
    set -euo pipefail
    backup() { [[ -e "$1" && ! -L "$1" ]] && mv "$1" "$1-old" && echo "⚠ moved $1 → $1-old"; true; }
    [[ -d "{{dotfiles}}/nushell" ]] || exit 0
    mkdir -p "$HOME/.config" "$HOME/bin"
    backup "$HOME/.config/nushell"
    ln -sfn "{{dotfiles}}/nushell/config" "$HOME/.config/nushell"
    echo "✓ nushell → ~/.config/nushell"
    (cd "{{dotfiles}}/nushell/startnu" && go build -o "$HOME/bin/nu" ./cmd/startnu)
    echo "✓ built nu → ~/bin/nu"
    if [[ "$(uname)" == "Darwin" ]]; then
        backup "$HOME/Library/Application Support/nushell"
        ln -sfn "{{dotfiles}}/nushell/config" "$HOME/Library/Application Support/nushell"
        echo "✓ nushell → ~/Library/Application Support/nushell"
    fi

[private]
_gnupg:
    #!/usr/bin/env bash
    set -euo pipefail
    backup() { [[ -e "$1" && ! -L "$1" ]] && mv "$1" "$1-old" && echo "⚠ moved $1 → $1-old"; true; }
    [[ -d "{{dotfiles}}/gnupg" ]] || exit 0
    mkdir -p "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"
    backup "$HOME/.gnupg/gpg.conf"
    ln -sfn "{{dotfiles}}/gnupg/gpg.conf" "$HOME/.gnupg/gpg.conf"
    backup "$HOME/.gnupg/gpg-agent.conf"
    ln -sfn "{{dotfiles}}/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
    if [[ -f "{{dotfiles}}/gnupg/scdaemon.conf" ]]; then
        backup "$HOME/.gnupg/scdaemon.conf"
        ln -sfn "{{dotfiles}}/gnupg/scdaemon.conf" "$HOME/.gnupg/scdaemon.conf"
    fi
    echo "✓ gnupg → ~/.gnupg/"

[private]
_jj:
    #!/usr/bin/env bash
    set -euo pipefail
    backup() { [[ -e "$1" && ! -L "$1" ]] && mv "$1" "$1-old" && echo "⚠ moved $1 → $1-old"; true; }
    [[ -d "{{dotfiles}}/jj" ]] || exit 0
    mkdir -p "$HOME/.config/jj/conf.d"
    backup "$HOME/.config/jj/config.toml"
    ln -sfn "{{dotfiles}}/jj/config.toml" "$HOME/.config/jj/config.toml"
    for f in "{{dotfiles}}/jj/conf.d"/*; do
        if [[ -e "$f" ]]; then
            target="$HOME/.config/jj/conf.d/$(basename "$f")"
            backup "$target"
            ln -sfn "$f" "$target"
        fi
    done
    echo "✓ jj → ~/.config/jj/"

[private]
_git:
    #!/usr/bin/env bash
    set -euo pipefail
    backup() { [[ -e "$1" && ! -L "$1" ]] && mv "$1" "$1-old" && echo "⚠ moved $1 → $1-old"; true; }
    [[ -d "{{dotfiles}}/git" ]] || exit 0
    for f in "{{dotfiles}}/git"/*; do
        target="$HOME/.$(basename "$f")"
        backup "$target"
        ln -sfn "$f" "$target"
    done
    echo "✓ git/* → ~/.*"

[private]
_fish:
    #!/usr/bin/env bash
    set -euo pipefail
    backup() { [[ -e "$1" && ! -L "$1" ]] && mv "$1" "$1-old" && echo "⚠ moved $1 → $1-old"; true; }
    [[ -d "{{dotfiles}}/fish" ]] || exit 0
    mkdir -p "$HOME/.config" "$HOME/.local/bin"
    backup "$HOME/.config/fish"
    ln -sfn "{{dotfiles}}/fish" "$HOME/.config/fish"
    echo "✓ fish → ~/.config/fish"
    printf '%s\n' '#!/bin/sh' \
        'if [ "$(uname)" = "Darwin" ]; then' \
        '    exec /opt/homebrew/bin/fish "$@"' \
        'else' \
        '    exec /home/linuxbrew/.linuxbrew/bin/fish "$@"' \
        'fi' > "$HOME/.local/bin/fish.sh"
    chmod +x "$HOME/.local/bin/fish.sh"
    echo "✓ created ~/.local/bin/fish.sh"

# Individual tool install aliases
zsh: _zsh
claude: _claude
codex: _codex
nushell: _nushell
gnupg: _gnupg
jj: _jj
git: _git
fish: _fish

# Install a specific config directory by name
config name:
    #!/usr/bin/env bash
    set -euo pipefail
    backup() { [[ -e "$1" && ! -L "$1" ]] && mv "$1" "$1-old" && echo "⚠ moved $1 → $1-old"; true; }
    mkdir -p ~/.config
    backup "$HOME/.config/{{name}}"
    ln -sfn "{{dotfiles}}/{{name}}" "$HOME/.config/{{name}}"
    echo "✓ {{name}} → ~/.config/{{name}}"

# Run macOS defaults script
macos:
    @[ "$(uname)" = "Darwin" ] && "{{dotfiles}}/scripts/macos-defaults.sh" || echo "skip: not macOS"

# Install Homebrew packages
brew:
    brew bundle --file={{dotfiles}}/Brewfile

# Remove all symlinks
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Config dirs
    for dir in {{config_dirs}}; do
        [ -L "$HOME/.config/$dir" ] && rm "$HOME/.config/$dir" && echo "✗ ~/.config/$dir"
    done
    
    # Special cases
    [ -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc" && echo "✗ ~/.zshrc"
    [ -L "$HOME/.claude" ] && rm "$HOME/.claude" && echo "✗ ~/.claude"
    [ -L "$HOME/.codex" ] && rm "$HOME/.codex" && echo "✗ ~/.codex"
    [ -L "$HOME/.config/nushell" ] && rm "$HOME/.config/nushell" && echo "✗ ~/.config/nushell"
    [ -e "$HOME/bin/nu" ] && rm "$HOME/bin/nu" && echo "✗ ~/bin/nu"
    [ -L "$HOME/.config/fish" ] && rm "$HOME/.config/fish" && echo "✗ ~/.config/fish"
    [ -e "$HOME/.local/bin/fish.sh" ] && rm "$HOME/.local/bin/fish.sh" && echo "✗ ~/.local/bin/fish.sh"
    
    for f in gpg.conf gpg-agent.conf scdaemon.conf; do
        [ -L "$HOME/.gnupg/$f" ] && rm "$HOME/.gnupg/$f" && echo "✗ ~/.gnupg/$f"
    done
    
    [ -L "$HOME/.config/jj/config.toml" ] && rm "$HOME/.config/jj/config.toml" && echo "✗ ~/.config/jj/config.toml"
    for f in "$HOME/.config/jj/conf.d"/*; do
        [ -L "$f" ] && rm "$f" && echo "✗ $f"
    done
    
    for f in "{{dotfiles}}/git"/*; do
        t="$HOME/.$(basename "$f")"
        [ -L "$t" ] && rm "$t" && echo "✗ $t"
    done
    
    if [ "$(uname)" = "Darwin" ]; then
        [ -L "$HOME/Library/Application Support/nushell" ] && rm "$HOME/Library/Application Support/nushell" && echo "✗ ~/Library/Application Support/nushell"
    fi
    
    echo "done"

# Check symlink status
status:
    #!/usr/bin/env bash
    set -euo pipefail
    
    check() { [ -L "$1" ] && echo "✓ $2 → $(readlink "$1")" || echo "✗ $2"; }
    check_exists() { [ -e "$1" ] && echo "✓ $2" || echo "✗ $2"; }
    
    for dir in {{config_dirs}}; do
        check "$HOME/.config/$dir" "$dir"
    done
    
    check "$HOME/.zshrc" ".zshrc"
    check "$HOME/.claude" ".claude"
    check "$HOME/.codex" ".codex"
    check "$HOME/.config/nushell" "nushell"
    check_exists "$HOME/bin/nu" "~/bin/nu"
    check "$HOME/.config/fish" "fish"
    check_exists "$HOME/.local/bin/fish.sh" "fish.sh"
    check "$HOME/.gnupg/gpg.conf" "gpg.conf"
    check "$HOME/.gnupg/gpg-agent.conf" "gpg-agent.conf"
    check "$HOME/.config/jj/config.toml" "jj/config.toml"
    
    if [ "$(uname)" = "Darwin" ]; then
        check "$HOME/Library/Application Support/nushell" "nushell (macOS)"
    fi

clean: uninstall
