# Makefile for dotfiles symlink management

# Get the directory where this Makefile is located
DOTFILES_DIR := $(shell pwd)

# Auto-detect all subdirectories (excluding dot directories and special cases)
ALL_DIRS := $(shell find . -maxdepth 1 -type d ! -name '.*' ! -name 'zsh' ! -name 'claude' ! -name 'nushell' -exec basename {} \;)

# Special cases that don't go to ~/.config/
SPECIAL_CASES := claude zsh nushell

# Directories that should be linked to ~/.config/
CONFIG_DIRS := $(filter-out $(SPECIAL_CASES), $(ALL_DIRS))

# Default target
.PHONY: all
all: install

# Install all symlinks
.PHONY: install
install: install-config install-special

# Install config directories
.PHONY: install-config
install-config:
	@mkdir -p ~/.config
	@for dir in $(CONFIG_DIRS); do \
		echo "Creating symlink for $$dir..."; \
		ln -sfn $(DOTFILES_DIR)/$$dir ~/.config/$$dir; \
		echo "✓ Linked $$dir to ~/.config/$$dir"; \
	done

# Install special cases
.PHONY: install-special
install-special:
	@if [ -d "nushell" ]; then \
		echo "Setting up nushell..."; \
		mkdir -p "$$HOME/.config"; \
		ln -sfn $(DOTFILES_DIR)/nushell "$$HOME/.config/nushell"; \
		echo "✓ Linked nushell to $$HOME/.config/nushell"; \
		mkdir -p "$$HOME/bin"; \
		( \
			cd "$(DOTFILES_DIR)/nushell/startnu" && \
			go build -o "$$HOME/bin/nu" ./cmd/startnu \
		); \
		echo "✓ Built nu to $$HOME/bin/nu"; \
		if [ "$$(uname)" = "Darwin" ]; then \
			SUPPORT_DIR="$$HOME/Library/Application Support"; \
			mkdir -p "$$SUPPORT_DIR"; \
			ln -sfn $(DOTFILES_DIR)/nushell "$$SUPPORT_DIR/nushell"; \
			echo "✓ Linked nushell to $$SUPPORT_DIR/nushell"; \
		fi; \
	fi
	@if [ -d "zsh" ]; then \
		echo "Creating symlink for .zshrc..."; \
		ln -sfn $(DOTFILES_DIR)/zsh/zshrc ~/.zshrc; \
		echo "✓ Linked zsh/zshrc to ~/.zshrc"; \
	fi
	@if [ -d "claude" ]; then \
		echo "Creating symlink for .claude..."; \
		ln -sfn $(DOTFILES_DIR)/claude ~/.claude; \
		echo "✓ Linked claude to ~/.claude"; \
	fi

# Individual target for any directory (works for both config and special cases)
.PHONY: $(ALL_DIRS) $(SPECIAL_CASES)
$(filter-out $(SPECIAL_CASES), $(ALL_DIRS)):
	@echo "Creating symlink for $@..."
	@mkdir -p ~/.config
	@ln -sfn $(DOTFILES_DIR)/$@ ~/.config/$@
	@echo "✓ Linked $@ to ~/.config/$@"

zsh:
	@echo "Creating symlink for .zshrc..."
	@ln -sfn $(DOTFILES_DIR)/zsh/zshrc ~/.zshrc
	@echo "✓ Linked zsh/zshrc to ~/.zshrc"

claude:
	@echo "Creating symlink for .claude..."
	@ln -sfn $(DOTFILES_DIR)/claude ~/.claude
	@echo "✓ Linked claude to ~/.claude"

nushell:
	@echo "Setting up nushell..."
	@mkdir -p "$$HOME/.config"
	@ln -sfn $(DOTFILES_DIR)/nushell/config "$$HOME/.config/nushell"
	@echo "✓ Linked nushell to $$HOME/.config/nushell"
	@mkdir -p "$$HOME/bin"
	@( \
		cd "$(DOTFILES_DIR)/nushell/startnu" && \
		go build -o "$$HOME/bin/nu" ./cmd/startnu \
	)
	@echo "✓ Built nu to $$HOME/bin/nu"
	@if [ "$$(uname)" = "Darwin" ]; then \
		SUPPORT_DIR="$$HOME/Library/Application Support"; \
		mkdir -p "$$SUPPORT_DIR"; \
		ln -sfn $(DOTFILES_DIR)/nushell/config "$$SUPPORT_DIR/nushell"; \
		echo "✓ Linked nushell to $$SUPPORT_DIR/nushell"; \
	fi

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
	@if [ -L "$$HOME/.config/nushell" ]; then \
		rm "$$HOME/.config/nushell"; \
		echo "✓ Removed $$HOME/.config/nushell"; \
	fi
	@if [ -e "$$HOME/bin/nu" ]; then \
		rm "$$HOME/bin/nu"; \
		echo "✓ Removed $$HOME/bin/nu"; \
	fi
	@if [ "$$(uname)" = "Darwin" ]; then \
		SUPPORT_DIR="$$HOME/Library/Application Support"; \
		if [ -L "$$SUPPORT_DIR/nushell" ]; then \
			rm "$$SUPPORT_DIR/nushell"; \
			echo "✓ Removed $$SUPPORT_DIR/nushell"; \
		fi; \
	fi
	@if [ -L ~/.zshrc ]; then \
		rm ~/.zshrc; \
		echo "✓ Removed ~/.zshrc"; \
	fi
	@if [ -L ~/.claude ]; then \
		rm ~/.claude; \
		echo "✓ Removed ~/.claude"; \
	fi

# Check status of symlinks
.PHONY: status
status:
	@echo "Checking symlink status..."
	@echo "Auto-detected directories: $(CONFIG_DIRS)"
	@echo "Special cases: $(SPECIAL_CASES)"
	@echo ""
	@for dir in $(CONFIG_DIRS); do \
		if [ -L ~/.config/$$dir ]; then \
			echo "✓ $$dir is linked to $$(readlink ~/.config/$$dir)"; \
		else \
			echo "✗ $$dir is not linked"; \
		fi; \
	done
	@if [ -d "zsh" ]; then \
		if [ -L ~/.zshrc ]; then \
			echo "✓ .zshrc is linked to $$(readlink ~/.zshrc)"; \
		else \
			echo "✗ .zshrc is not linked"; \
		fi; \
	fi
	@if [ -d "claude" ]; then \
		if [ -L ~/.claude ]; then \
			echo "✓ .claude is linked to $$(readlink ~/.claude)"; \
		else \
			echo "✗ .claude is not linked"; \
		fi; \
	fi
	@if [ -d "nushell" ]; then \
		if [ -L $$HOME/.config/nushell ]; then \
			echo "✓ nushell config is linked to $$(readlink $$HOME/.config/nushell)"; \
		else \
			echo "✗ nushell config is not linked"; \
		fi; \
		if [ -x $$HOME/bin/nu ]; then \
			echo "✓ nu exists and is executable in $$HOME/bin"; \
		else \
			echo "✗ nu is missing or not executable in $$HOME/bin"; \
		fi; \
		if [ "$$(uname)" = "Darwin" ]; then \
			SUPPORT_DIR="$$HOME/Library/Application Support"; \
			if [ -L "$$SUPPORT_DIR/nushell" ]; then \
				LINK_TARGET=$$(readlink "$$SUPPORT_DIR/nushell"); \
				echo "✓ macOS nushell link points to $$LINK_TARGET"; \
			else \
				echo "✗ macOS nushell link is missing"; \
			fi; \
		fi; \
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
	@echo "Auto-detected tools:"
	@echo "  $(CONFIG_DIRS)"
	@echo ""
	@echo "Special cases:"
	@echo "  zsh (links to ~/.zshrc)"
	@echo "  claude (links to ~/.claude)"
	@echo "  nushell (links config, builds nu shim, macOS support link)"

# Clean target (just an alias for uninstall)
.PHONY: clean
clean: uninstall
