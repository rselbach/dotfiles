# Makefile for dotfiles symlink management

# Get the directory where this Makefile is located
DOTFILES_DIR := $(shell pwd)

# Auto-detect all subdirectories (excluding dot directories and special cases)
ALL_DIRS := $(shell find . -maxdepth 1 -type d ! -name '.*' ! -name 'zsh' ! -name 'claude' ! -name 'nushell' -exec basename {} \;)

# Special cases that don't go to ~/.config/
SPECIAL_CASES := claude zsh nushell git fish gnupg jj scripts

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
		ln -sfn $(DOTFILES_DIR)/nushell/config "$$HOME/.config/nushell"; \
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
			ln -sfn $(DOTFILES_DIR)/nushell/config "$$SUPPORT_DIR/nushell"; \
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
	@if [ -d "gnupg" ]; then \
		echo "Setting up gnupg..."; \
		mkdir -p "$$HOME/.gnupg"; \
		chmod 700 "$$HOME/.gnupg"; \
		ln -sfn $(DOTFILES_DIR)/gnupg/gpg.conf "$$HOME/.gnupg/gpg.conf"; \
		ln -sfn $(DOTFILES_DIR)/gnupg/gpg-agent.conf "$$HOME/.gnupg/gpg-agent.conf"; \
		if [ -f "$(DOTFILES_DIR)/gnupg/scdaemon.conf" ]; then \
			ln -sfn $(DOTFILES_DIR)/gnupg/scdaemon.conf "$$HOME/.gnupg/scdaemon.conf"; \
		fi; \
		echo "✓ Linked gnupg configs to ~/.gnupg/"; \
	fi
	@if [ -d "jj" ]; then \
		echo "Setting up jujutsu..."; \
		mkdir -p "$$HOME/.config/jj/conf.d"; \
		ln -sfn $(DOTFILES_DIR)/jj/config.toml "$$HOME/.config/jj/config.toml"; \
		if [ -d "$(DOTFILES_DIR)/jj/conf.d" ]; then \
			for f in $(DOTFILES_DIR)/jj/conf.d/*; do \
				ln -sfn "$$f" "$$HOME/.config/jj/conf.d/$$(basename $$f)"; \
			done; \
		fi; \
		echo "✓ Linked jj configs to ~/.config/jj/"; \
	fi
	@if [ -d "git" ]; then \
		echo "Setting up git..."; \
		for i in $(DOTFILES_DIR)/git/*; do ln -sfn "$$i" "$$HOME/.$${i##*/}"; done; \
		echo "✓ Linked git/* to ~/"; \
	fi
	@if [ -d "fish" ]; then \
		echo "Setting up fish..."; \
		mkdir -p "$$HOME/.config"; \
		ln -sfn $(DOTFILES_DIR)/fish "$$HOME/.config/fish"; \
		echo "✓ Linked fish to $$HOME/.config/fish"; \
		mkdir -p "$$HOME/.local/bin"; \
		echo '#!/bin/sh' > "$$HOME/.local/bin/fish.sh"; \
		if [ "$$(uname)" = "Darwin" ]; then \
			echo 'exec /opt/homebrew/bin/fish "$$@"' >> "$$HOME/.local/bin/fish.sh"; \
		else \
			echo 'exec /home/linuxbrew/.linuxbrew/bin/fish "$$@"' >> "$$HOME/.local/bin/fish.sh"; \
		fi; \
		chmod +x "$$HOME/.local/bin/fish.sh"; \
		echo "✓ Created $$HOME/.local/bin/fish.sh"; \
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

git:
	@echo "Creating symlink for .gitconfig..."
	@for i in $(DOTFILES_DIR)/git/*; do ln -sfn "$$i" "$$HOME/.$${i##*/}"; done
	@echo "✓ Linked git/* to ~/"


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

fish:
	@echo "Setting up fish..."
	@mkdir -p "$$HOME/.config"
	@ln -sfn $(DOTFILES_DIR)/fish "$$HOME/.config/fish"
	@echo "✓ Linked fish to $$HOME/.config/fish"
	@mkdir -p "$$HOME/.local/bin"
	@echo '#!/bin/sh' > "$$HOME/.local/bin/fish.sh"
	@echo 'if [ "$$(uname)" = "Darwin" ]; then' >> "$$HOME/.local/bin/fish.sh"
	@echo '    exec /opt/homebrew/bin/fish "$$@"' >> "$$HOME/.local/bin/fish.sh"
	@echo 'else' >> "$$HOME/.local/bin/fish.sh"
	@echo '    exec /home/linuxbrew/.linuxbrew/bin/fish "$$@"' >> "$$HOME/.local/bin/fish.sh"
	@echo 'fi' >> "$$HOME/.local/bin/fish.sh"
	@chmod +x "$$HOME/.local/bin/fish.sh"
	@echo "✓ Created $$HOME/.local/bin/fish.sh"

gnupg:
	@echo "Setting up gnupg..."
	@mkdir -p "$$HOME/.gnupg"
	@chmod 700 "$$HOME/.gnupg"
	@ln -sfn $(DOTFILES_DIR)/gnupg/gpg.conf "$$HOME/.gnupg/gpg.conf"
	@ln -sfn $(DOTFILES_DIR)/gnupg/gpg-agent.conf "$$HOME/.gnupg/gpg-agent.conf"
	@if [ -f "$(DOTFILES_DIR)/gnupg/scdaemon.conf" ]; then \
		ln -sfn $(DOTFILES_DIR)/gnupg/scdaemon.conf "$$HOME/.gnupg/scdaemon.conf"; \
	fi
	@echo "✓ Linked gnupg configs to ~/.gnupg/"

jj:
	@echo "Setting up jujutsu..."
	@mkdir -p "$$HOME/.config/jj/conf.d"
	@ln -sfn $(DOTFILES_DIR)/jj/config.toml "$$HOME/.config/jj/config.toml"
	@if [ -d "$(DOTFILES_DIR)/jj/conf.d" ]; then \
		for f in $(DOTFILES_DIR)/jj/conf.d/*; do \
			ln -sfn "$$f" "$$HOME/.config/jj/conf.d/$$(basename $$f)"; \
		done; \
	fi
	@echo "✓ Linked jj configs to ~/.config/jj/"

macos:
	@if [ "$$(uname)" = "Darwin" ]; then \
		echo "Running macOS defaults script..."; \
		$(DOTFILES_DIR)/scripts/macos-defaults.sh; \
	else \
		echo "Skipping macOS defaults (not on macOS)"; \
	fi

brew:
	@echo "Installing Homebrew packages..."
	@brew bundle --file=$(DOTFILES_DIR)/Brewfile
	@echo "✓ Homebrew packages installed"

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
	@if [ -L "$$HOME/.config/fish" ]; then \
		rm "$$HOME/.config/fish"; \
		echo "✓ Removed $$HOME/.config/fish"; \
	fi
	@if [ -e "$$HOME/.local/bin/fish.sh" ]; then \
		rm "$$HOME/.local/bin/fish.sh"; \
		echo "✓ Removed $$HOME/.local/bin/fish.sh"; \
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
	@if [ -d "fish" ]; then \
		if [ -L $$HOME/.config/fish ]; then \
			echo "✓ fish is linked to $$(readlink $$HOME/.config/fish)"; \
		else \
			echo "✗ fish is not linked"; \
		fi; \
		if [ -x $$HOME/.local/bin/fish.sh ]; then \
			echo "✓ fish.sh exists and is executable"; \
		else \
			echo "✗ fish.sh is missing or not executable"; \
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
	@echo "  make brew      - Install Homebrew packages from Brewfile"
	@echo "  make macos     - Apply macOS system defaults"
	@echo "  make <tool>    - Install specific tool (e.g., make nvim)"
	@echo ""
	@echo "Auto-detected tools:"
	@echo "  $(CONFIG_DIRS)"
	@echo ""
	@echo "Special cases:"
	@echo "  zsh (links to ~/.zshrc)"
	@echo "  git (links git/* to ~/.*)"
	@echo "  gnupg (links to ~/.gnupg/)"
	@echo "  jj (links to ~/.config/jj/)"
	@echo "  claude (links to ~/.claude)"
	@echo "  nushell (links config, builds nu shim, macOS support link)"
	@echo "  fish (links config, creates ~/.local/bin/fish.sh wrapper)"

# Clean target (just an alias for uninstall)
.PHONY: clean
clean: uninstall
