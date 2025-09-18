# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview
This is a dotfiles repository containing configuration files for various development tools. Each top-level directory corresponds to a tool and contains its configuration files.

## Directory Structure
Each directory contains configuration files for its respective tool:
- `ghostty/` - Ghostty terminal emulator configuration with catppuccin themes
- `nushell/` - Nushell shell configuration
- `nvim/` - Neovim configuration using LazyVim
- `starship/` - Starship prompt configuration
- `tmux/` - Tmux configuration with custom settings and reset file
- `zellij/` - Zellij terminal multiplexer configuration
- `zsh/` - Zsh shell configuration with starship integration

## Configuration Notes
- Git ignores: `history.txt`, `tmux/plugins`
- Nvim uses LazyVim with custom plugins managed in `lazy-lock.json`
- Zsh sources starship prompt and kube-ps1 for Kubernetes context display
- Ghostty uses catppuccin-mocha theme with JetBrainsMono Nerd Font
- All configuration files are stored directly in their respective directories

## Installation and Management

### Using Make
The repository includes a Makefile for managing symlinks:

```bash
make install   # Create all symlinks (default)
make uninstall # Remove all symlinks
make status    # Check status of all symlinks
make nvim      # Install specific tool
make help      # Show all available commands
```

### File Locations
When installed, symlinks are created:
- `ghostty/` → `~/.config/ghostty/`
- `nushell/` → `~/.config/nushell/`
- `nvim/` → `~/.config/nvim/`
- `starship/` → `~/.config/starship/`
- `tmux/` → `~/.config/tmux/`
- `zellij/` → `~/.config/zellij/`
- `zsh/.zshrc` → `~/.zshrc`