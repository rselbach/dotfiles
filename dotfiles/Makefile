# Makefile for dotfiles symlink management

# Get the directory where this Makefile is located
DOTFILES_DIR := $(shell pwd)

# Define all configuration directories (excluding dot directories and zsh)
CONFIG_DIRS := ghostty nushell nvim starship tmux zellij

# Default target
.PHONY: all
all: install

# Install all symlinks
.PHONY: install
install: $(CONFIG_DIRS) zsh

# Individual targets for each config directory
.PHONY: $(CONFIG_DIRS)
$(CONFIG_DIRS):
	@echo "Creating symlink for $@..."
	@mkdir -p ~/.config
	@ln -sfn $(DOTFILES_DIR)/$@ ~/.config/$@
	@echo "✓ Linked $@ to ~/.config/$@"

# Special target for zsh (goes directly to home)
.PHONY: zsh
zsh:
	@echo "Creating symlink for .zshrc..."
	@ln -sfn $(DOTFILES_DIR)/zsh/.zshrc ~/.zshrc
	@echo "✓ Linked zsh/.zshrc to ~/.zshrc"

# Uninstall all symlinks
.PHONY: uninstall
uninstall:
	@echo "Removing symlinks..."
	@for dir in $(CONFIG_DIRS); do \
		if [ -L ~/.config/$$dir ]; then \
			rm ~/.config/$$dir; \
			echo "✓ Removed ~/.config/$$dir"; \
		fi; \
	done
	@if [ -L ~/.zshrc ]; then \
		rm ~/.zshrc; \
		echo "✓ Removed ~/.zshrc"; \
	fi

# Check status of symlinks
.PHONY: status
status:
	@echo "Checking symlink status..."
	@for dir in $(CONFIG_DIRS); do \
		if [ -L ~/.config/$$dir ]; then \
			echo "✓ $$dir is linked to $$(readlink ~/.config/$$dir)"; \
		else \
			echo "✗ $$dir is not linked"; \
		fi; \
	done
	@if [ -L ~/.zshrc ]; then \
		echo "✓ .zshrc is linked to $$(readlink ~/.zshrc)"; \
	else \
		echo "✗ .zshrc is not linked"; \
	fi

# Help target
.PHONY: help
help:
	@echo "Dotfiles Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make install   - Create all symlinks (default)"
	@echo "  make uninstall - Remove all symlinks"
	@echo "  make status    - Check status of all symlinks"
	@echo "  make <tool>    - Install specific tool (e.g., make nvim)"
	@echo ""
	@echo "Available tools:"
	@echo "  $(CONFIG_DIRS) zsh"

# Clean target (just an alias for uninstall)
.PHONY: clean
clean: uninstall