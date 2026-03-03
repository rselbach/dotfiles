# Dotfiles symlink manager

dotfiles := justfile_directory()

default:
    @just --list

install *args:
    python3 {{dotfiles}}/install.py install {{args}}

uninstall:
    python3 {{dotfiles}}/install.py uninstall

status:
    python3 {{dotfiles}}/install.py status

macos:
    @[ "$(uname)" = "Darwin" ] && "{{dotfiles}}/scripts/macos-defaults.sh" || echo "skip: not macOS"

brew:
    brew bundle --file={{dotfiles}}/Brewfile
