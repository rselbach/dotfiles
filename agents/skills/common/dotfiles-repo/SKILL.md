---
name: dotfiles-repo
description: Dotfiles repo, Makefile, install.py, .config.toml, symlinked config, ~/.config, and files under $HOME already managed from ~/devel/dotfiles. Use when the user asks to change personal shell/editor/terminal/tool configuration or another machine-level config that may already live in the dotfiles repo. Edit existing managed configuration at its repo source, but never add new configuration to the repo unless the user explicitly asks. Do not use for project-local app config.
---

# Dotfiles Repo

## Source of Truth

Some of the user's personal machine configuration is managed from
`~/devel/dotfiles`.

When a request touches tool or machine config (`nvim`, `ghostty`, `tmux`, `zsh`,
`git`, `opencode`, `claude`, `karabiner`, etc.), check whether the repo already
owns it. If it does, change the repo source instead of the live file under
`$HOME`. If it does not, leave it outside the dotfiles system unless the user
explicitly asks to manage it there.

## Management Boundary

- Existing config units and links remain managed by this repo.
- Never create a new top-level file or directory in `~/devel/dotfiles` for an
  unmanaged tool or configuration unless the user explicitly asks to add or
  manage it in dotfiles.
- Do not migrate, copy, move, or symlink unmanaged configuration into this repo
  merely because the request concerns machine configuration.
- When configuration is not currently managed, edit its normal live location
  if the user requested a change there.
- If ownership is unclear, inspect the installer and symlinks. If it remains
  unclear whether the user wants dotfiles management, ask before adding it.

## How to Find the Real File to Edit

1. Trace the requested path to its managed source using existing links.
2. When ownership, rendering, or installation behavior is unclear, consult the
   unit's `.config.toml` and [installer reference](references/installer.md).
3. Read relevant parts of `~/devel/dotfiles/install.py` only when needed to
   resolve remaining questions.
4. Edit the repo source, not an installed or rendered destination.

## Editing Rules

- Do not edit managed files in `$HOME` when the repo owns them, unless the user explicitly wants a one-off local change.
- If the request names a live path, trace it back to the dotfiles repo before modifying it.
- Create a new config unit only when the user explicitly asks to add or manage
  that configuration in dotfiles. Otherwise, keep it at its normal live path.
- When the user explicitly requests a new config unit, decide whether the
  default `~/.config/<name>` link is correct. If not, add a `.config.toml`.
- Use explicit `[[links]]` for non-`~/.config` targets, host/OS-specific files, globs, or templated secrets.

## Verification

Prefer the repo `Makefile`:

- `make status`
- `make install`
- `make install DIRS=<unit>`
- `make uninstall`
- `make macos`
- `make brew`

Use `make install DIRS=<unit>` after changing one config unit when the user wants the change applied.

## Watchouts

- Existing non-symlink destinations are moved to `*-old` during install.
- Host-specific links beat universal and OS-specific links for the same destination.
- If all `[[links]]` are filtered out for the current OS or host, nothing is linked for that config unit.
- Repository branches are updated by fast-forward only; tags and commit SHAs are checked out detached.
- Repository destinations are not removed by `uninstall`.
