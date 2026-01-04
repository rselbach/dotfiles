# Justfile for dotfiles symlink management

# Get the directory where this justfile is located
dotfiles_dir := justfile_directory()

# Special cases that don't go to ~/.config/
special_cases := "claude zsh nushell git fish gnupg jj scripts"

# Auto-detect config directories (excluding dot dirs and special cases)
config_dirs := `find . -maxdepth 1 -type d ! -name '.*' ! -name 'zsh' ! -name 'claude' ! -name 'nushell' ! -name 'git' ! -name 'fish' ! -name 'gnupg' ! -name 'jj' ! -name 'scripts' -exec basename {} \; | tr '\n' ' '`

# Default recipe - show help
default:
    @just --list

# Install all symlinks
install: install-config install-special

# Install config directories
install-config:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p ~/.config
    for dir in {{config_dirs}}; do
        echo "Creating symlink for $dir..."
        ln -sfn "{{dotfiles_dir}}/$dir" "$HOME/.config/$dir"
        echo "✓ Linked $dir to ~/.config/$dir"
    done

# Install special cases
install-special: _install-nushell _install-zsh _install-claude _install-gnupg _install-jj _install-git _install-fish

_install-nushell:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{dotfiles_dir}}/nushell" ]; then
        echo "Setting up nushell..."
        mkdir -p "$HOME/.config"
        ln -sfn "{{dotfiles_dir}}/nushell/config" "$HOME/.config/nushell"
        echo "✓ Linked nushell to $HOME/.config/nushell"
        mkdir -p "$HOME/bin"
        (
            cd "{{dotfiles_dir}}/nushell/startnu" && \
            go build -o "$HOME/bin/nu" ./cmd/startnu
        )
        echo "✓ Built nu to $HOME/bin/nu"
        if [ "$(uname)" = "Darwin" ]; then
            SUPPORT_DIR="$HOME/Library/Application Support"
            mkdir -p "$SUPPORT_DIR"
            ln -sfn "{{dotfiles_dir}}/nushell/config" "$SUPPORT_DIR/nushell"
            echo "✓ Linked nushell to $SUPPORT_DIR/nushell"
        fi
    fi

_install-zsh:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{dotfiles_dir}}/zsh" ]; then
        echo "Creating symlink for .zshrc..."
        ln -sfn "{{dotfiles_dir}}/zsh/zshrc" "$HOME/.zshrc"
        echo "✓ Linked zsh/zshrc to ~/.zshrc"
    fi

_install-claude:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{dotfiles_dir}}/claude" ]; then
        echo "Creating symlink for .claude..."
        ln -sfn "{{dotfiles_dir}}/claude" "$HOME/.claude"
        echo "✓ Linked claude to ~/.claude"
    fi

_install-gnupg:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{dotfiles_dir}}/gnupg" ]; then
        echo "Setting up gnupg..."
        mkdir -p "$HOME/.gnupg"
        chmod 700 "$HOME/.gnupg"
        ln -sfn "{{dotfiles_dir}}/gnupg/gpg.conf" "$HOME/.gnupg/gpg.conf"
        ln -sfn "{{dotfiles_dir}}/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
        if [ -f "{{dotfiles_dir}}/gnupg/scdaemon.conf" ]; then
            ln -sfn "{{dotfiles_dir}}/gnupg/scdaemon.conf" "$HOME/.gnupg/scdaemon.conf"
        fi
        echo "✓ Linked gnupg configs to ~/.gnupg/"
    fi

_install-jj:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{dotfiles_dir}}/jj" ]; then
        echo "Setting up jujutsu..."
        mkdir -p "$HOME/.config/jj/conf.d"
        ln -sfn "{{dotfiles_dir}}/jj/config.toml" "$HOME/.config/jj/config.toml"
        if [ -d "{{dotfiles_dir}}/jj/conf.d" ]; then
            for f in "{{dotfiles_dir}}/jj/conf.d"/*; do
                ln -sfn "$f" "$HOME/.config/jj/conf.d/$(basename "$f")"
            done
        fi
        echo "✓ Linked jj configs to ~/.config/jj/"
    fi

_install-git:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{dotfiles_dir}}/git" ]; then
        echo "Setting up git..."
        for i in "{{dotfiles_dir}}/git"/*; do
            ln -sfn "$i" "$HOME/.$(basename "$i")"
        done
        echo "✓ Linked git/* to ~/"
    fi

_install-fish:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{dotfiles_dir}}/fish" ]; then
        echo "Setting up fish..."
        mkdir -p "$HOME/.config"
        ln -sfn "{{dotfiles_dir}}/fish" "$HOME/.config/fish"
        echo "✓ Linked fish to $HOME/.config/fish"
        mkdir -p "$HOME/.local/bin"
        cat > "$HOME/.local/bin/fish.sh" << 'EOF'
    #!/bin/sh
    if [ "$(uname)" = "Darwin" ]; then
        exec /opt/homebrew/bin/fish "$@"
    else
        exec /home/linuxbrew/.linuxbrew/bin/fish "$@"
    fi
    EOF
        chmod +x "$HOME/.local/bin/fish.sh"
        echo "✓ Created $HOME/.local/bin/fish.sh"
    fi

# Individual tool recipes
nushell: _install-nushell
zsh: _install-zsh
claude: _install-claude
gnupg: _install-gnupg
jj: _install-jj
git: _install-git
fish: _install-fish

# Install a specific config directory by name
config name:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Creating symlink for {{name}}..."
    mkdir -p ~/.config
    ln -sfn "{{dotfiles_dir}}/{{name}}" "$HOME/.config/{{name}}"
    echo "✓ Linked {{name}} to ~/.config/{{name}}"

# Run macOS defaults script
macos:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$(uname)" = "Darwin" ]; then
        echo "Running macOS defaults script..."
        "{{dotfiles_dir}}/scripts/macos-defaults.sh"
    else
        echo "Skipping macOS defaults (not on macOS)"
    fi

# Install Homebrew packages
brew:
    @echo "Installing Homebrew packages..."
    brew bundle --file={{dotfiles_dir}}/Brewfile
    @echo "✓ Homebrew packages installed"

# Uninstall all symlinks
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Removing symlinks..."
    
    # Remove config dirs
    for dir in {{config_dirs}}; do
        if [ -L "$HOME/.config/$dir" ]; then
            rm "$HOME/.config/$dir"
            echo "✓ Removed ~/.config/$dir"
        fi
    done
    
    # Remove nushell
    if [ -L "$HOME/.config/nushell" ]; then
        rm "$HOME/.config/nushell"
        echo "✓ Removed $HOME/.config/nushell"
    fi
    if [ -e "$HOME/bin/nu" ]; then
        rm "$HOME/bin/nu"
        echo "✓ Removed $HOME/bin/nu"
    fi
    if [ "$(uname)" = "Darwin" ]; then
        SUPPORT_DIR="$HOME/Library/Application Support"
        if [ -L "$SUPPORT_DIR/nushell" ]; then
            rm "$SUPPORT_DIR/nushell"
            echo "✓ Removed $SUPPORT_DIR/nushell"
        fi
    fi
    
    # Remove zsh
    if [ -L "$HOME/.zshrc" ]; then
        rm "$HOME/.zshrc"
        echo "✓ Removed ~/.zshrc"
    fi
    
    # Remove claude
    if [ -L "$HOME/.claude" ]; then
        rm "$HOME/.claude"
        echo "✓ Removed ~/.claude"
    fi
    
    # Remove fish
    if [ -L "$HOME/.config/fish" ]; then
        rm "$HOME/.config/fish"
        echo "✓ Removed $HOME/.config/fish"
    fi
    if [ -e "$HOME/.local/bin/fish.sh" ]; then
        rm "$HOME/.local/bin/fish.sh"
        echo "✓ Removed $HOME/.local/bin/fish.sh"
    fi
    
    # Remove gnupg
    for f in gpg.conf gpg-agent.conf scdaemon.conf; do
        if [ -L "$HOME/.gnupg/$f" ]; then
            rm "$HOME/.gnupg/$f"
            echo "✓ Removed ~/.gnupg/$f"
        fi
    done
    
    # Remove jj
    if [ -L "$HOME/.config/jj/config.toml" ]; then
        rm "$HOME/.config/jj/config.toml"
        echo "✓ Removed ~/.config/jj/config.toml"
    fi
    if [ -d "$HOME/.config/jj/conf.d" ]; then
        for f in "$HOME/.config/jj/conf.d"/*; do
            if [ -L "$f" ]; then
                rm "$f"
                echo "✓ Removed $f"
            fi
        done
    fi
    
    # Remove git
    for i in "{{dotfiles_dir}}/git"/*; do
        target="$HOME/.$(basename "$i")"
        if [ -L "$target" ]; then
            rm "$target"
            echo "✓ Removed $target"
        fi
    done

# Check status of symlinks
status:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Checking symlink status..."
    echo "Auto-detected directories: {{config_dirs}}"
    echo "Special cases: {{special_cases}}"
    echo ""
    
    # Check config dirs
    for dir in {{config_dirs}}; do
        if [ -L "$HOME/.config/$dir" ]; then
            echo "✓ $dir is linked to $(readlink "$HOME/.config/$dir")"
        else
            echo "✗ $dir is not linked"
        fi
    done
    
    # Check zsh
    if [ -d "{{dotfiles_dir}}/zsh" ]; then
        if [ -L "$HOME/.zshrc" ]; then
            echo "✓ .zshrc is linked to $(readlink "$HOME/.zshrc")"
        else
            echo "✗ .zshrc is not linked"
        fi
    fi
    
    # Check claude
    if [ -d "{{dotfiles_dir}}/claude" ]; then
        if [ -L "$HOME/.claude" ]; then
            echo "✓ .claude is linked to $(readlink "$HOME/.claude")"
        else
            echo "✗ .claude is not linked"
        fi
    fi
    
    # Check nushell
    if [ -d "{{dotfiles_dir}}/nushell" ]; then
        if [ -L "$HOME/.config/nushell" ]; then
            echo "✓ nushell config is linked to $(readlink "$HOME/.config/nushell")"
        else
            echo "✗ nushell config is not linked"
        fi
        if [ -x "$HOME/bin/nu" ]; then
            echo "✓ nu exists and is executable in $HOME/bin"
        else
            echo "✗ nu is missing or not executable in $HOME/bin"
        fi
        if [ "$(uname)" = "Darwin" ]; then
            SUPPORT_DIR="$HOME/Library/Application Support"
            if [ -L "$SUPPORT_DIR/nushell" ]; then
                echo "✓ macOS nushell link points to $(readlink "$SUPPORT_DIR/nushell")"
            else
                echo "✗ macOS nushell link is missing"
            fi
        fi
    fi
    
    # Check fish
    if [ -d "{{dotfiles_dir}}/fish" ]; then
        if [ -L "$HOME/.config/fish" ]; then
            echo "✓ fish is linked to $(readlink "$HOME/.config/fish")"
        else
            echo "✗ fish is not linked"
        fi
        if [ -x "$HOME/.local/bin/fish.sh" ]; then
            echo "✓ fish.sh exists and is executable"
        else
            echo "✗ fish.sh is missing or not executable"
        fi
    fi
    
    # Check gnupg
    if [ -d "{{dotfiles_dir}}/gnupg" ]; then
        for f in gpg.conf gpg-agent.conf; do
            if [ -L "$HOME/.gnupg/$f" ]; then
                echo "✓ $f is linked to $(readlink "$HOME/.gnupg/$f")"
            else
                echo "✗ $f is not linked"
            fi
        done
    fi
    
    # Check jj
    if [ -d "{{dotfiles_dir}}/jj" ]; then
        if [ -L "$HOME/.config/jj/config.toml" ]; then
            echo "✓ jj config.toml is linked to $(readlink "$HOME/.config/jj/config.toml")"
        else
            echo "✗ jj config.toml is not linked"
        fi
    fi

# Alias for uninstall
clean: uninstall
