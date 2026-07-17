# Dotfiles symlink manager

DOTFILES := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
DIRS ?=

.DEFAULT_GOAL := help

.PHONY: help install uninstall status macos brew

help:
	@printf '%s\n' \
		'Usage:' \
		'  make install [DIRS="nvim tmux"]' \
		'  make uninstall' \
		'  make status' \
		'  make macos' \
		'  make brew'

install:
	python3 "$(DOTFILES)/install.py" install $(DIRS)

uninstall:
	python3 "$(DOTFILES)/install.py" uninstall

status:
	python3 "$(DOTFILES)/install.py" status

macos:
	@if [ "$$(uname)" = "Darwin" ]; then \
		"$(DOTFILES)/scripts/macos-defaults.sh"; \
	else \
		echo "skip: not macOS"; \
	fi

brew:
	brew bundle --file="$(DOTFILES)/Brewfile"
