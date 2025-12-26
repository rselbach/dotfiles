# Migration Plan: Nix to Traditional macOS Setup

## Current State

**Nix repo:** `~/devel/nix/` — manages system + home via nix-darwin + home-manager
**Dotfiles repo:** `~/devel/dotfiles/` — existing Makefile-based symlink manager

Your dotfiles repo already has most of what you need:
- `zsh/zshrc` — nearly identical to Nix-generated version
- `starship/` — prompt config
- `Brewfile` — partial, needs expanding
- `Makefile` — symlink manager already working

**What's missing from dotfiles:**
- Git config (with conditional work config)
- Jujutsu config (with conditional work config)
- GPG config
- Some bash helper functions (1Password integrations)
- macOS defaults script

---

## Migration Steps

### Step 1: Add Missing Configs to Dotfiles

Create these in `~/devel/dotfiles/`:

| Directory | Files | Source |
|-----------|-------|--------|
| `git/` | `gitconfig`, `gitconfig-ibm` | Extract from `~/devel/nix/home/programs/git.nix` |
| `jj/` | `config.toml`, `conf.d/hashicorp.toml` | Extract from `~/devel/nix/home/programs/jj.nix` |
| `gnupg/` | `gpg.conf`, `gpg-agent.conf` | Extract from `~/devel/nix/home/programs/gpg.nix` |

### Step 2: Merge Shell Additions

Add to `zsh/zshrc`:
- `get-github-token()` function (from Nix)

Optionally add these from bash.nix if you still want them:
- `fetch-github-token` (populates ~/.netrc)
- API key fetchers (OpenAI, Anthropic, etc.)
- HashiCorp `hs()` / `hs-show()` / `hs-stop()` functions

### Step 3: Expand Brewfile

Current Brewfile has 21 items. Nix manages ~35+ packages.

Add missing packages:
```
# Missing from current Brewfile
brew "ast-grep"
brew "atuin"
brew "aws-cli"
brew "claude-code"
brew "coreutils"
brew "curl"
brew "findutils"
brew "gnumake"
brew "gnu-sed"
brew "just"
brew "pinentry-mac"
brew "python@3.12"
brew "sshuttle"
brew "tree"
brew "uv"
brew "watch"
brew "yarn"

# Casks
cask "1password"
cask "visual-studio-code"
cask "font-jetbrains-mono-nerd-font"
```

### Step 4: Create macOS Defaults Script

Create `~/devel/dotfiles/scripts/macos-defaults.sh` with all the Finder/Dock/Safari/security settings from nix-darwin.

Key settings to preserve:
- Finder: show hidden files, extensions, path bar, status bar
- Dock: left-aligned, no recents, icon sizes
- System: dark mode, 24-hour clock, battery %
- Security: disable guest user, enable TouchID for sudo
- Safari: disable autofill, enable dev menu

### Step 5: Update Makefile

Add targets:
- `git` target (already exists but verify)
- `gnupg` target for GPG configs
- `jj` target for Jujutsu config
- `macos` target to run defaults script

### Step 6: Decommission Nix

1. **Install from dotfiles:**
   ```bash
   cd ~/devel/dotfiles
   make install
   brew bundle
   ./scripts/macos-defaults.sh
   ```

2. **Uninstall nix-darwin:**
   ```bash
   nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A uninstaller
   ./result/bin/darwin-uninstaller
   ```

3. **Uninstall Nix:**
   ```bash
   /nix/nix-installer uninstall
   ```
   (If using Determinate Nix Installer. Otherwise: `sudo rm -rf /nix`)

4. **Clean up:**
   - Remove `~/devel/nix/` (or archive it)
   - Remove any Nix-related profile sourcing from shell init

---

## Files to Create/Modify

**Create:**
- `~/devel/dotfiles/git/gitconfig`
- `~/devel/dotfiles/git/gitconfig-ibm`
- `~/devel/dotfiles/jj/config.toml`
- `~/devel/dotfiles/jj/conf.d/hashicorp.toml`
- `~/devel/dotfiles/gnupg/gpg.conf`
- `~/devel/dotfiles/gnupg/gpg-agent.conf`
- `~/devel/dotfiles/scripts/macos-defaults.sh`

**Modify:**
- `~/devel/dotfiles/Brewfile` — add missing packages
- `~/devel/dotfiles/Makefile` — add new targets
- `~/devel/dotfiles/zsh/zshrc` — add missing functions (optional)
