---
name: dotfiles-repo
description: Dotfiles repo, Makefile, install.py, .config.toml, symlinked config, ~/.config, and files under $HOME managed from ~/devel/dotfiles. Use when the user asks to change personal shell/editor/terminal/tool configuration or another machine-level config that may live in the dotfiles repo. Prefer editing the repo source instead of the live installed file. Do not use for project-local app config.
---

# Dotfiles Repo

## Source of Truth

The user's personal machine configuration is managed from `~/devel/dotfiles`.

When a request touches tool or machine config (`nvim`, `ghostty`, `tmux`, `zsh`, `git`, `opencode`, `claude`, `karabiner`, etc.), assume the repo may own it. Prefer changing the repo source instead of editing a live file under `$HOME`.

## How to Find the Real File to Edit

1. Read `~/devel/dotfiles/install.py`.
2. Find the relevant top-level config unit in `~/devel/dotfiles/`.
3. Read that unit's `.config.toml` when present.
4. Edit the repo file that will be linked or rendered, not the installed destination.

Rules to remember:

- Each top-level, non-hidden directory is a config unit.
- Without a `.config.toml`, `./<name>` is symlinked to `~/.config/<name>`.
- `target = "..."` changes the whole-directory destination.
- If any `[[links]]` entries exist, the default whole-directory link is disabled.
- `[[links]]` can target paths outside `~/.config` and can be filtered by `os` or `hosts`.
- `src = "*"` expands inside the config unit; `<name>` in `dst` becomes the matched basename.
- `secrets = true` means the destination is rendered from secrets data; edit the repo template source, not the rendered file.

## Editing Rules

- Do not edit managed files in `$HOME` when the repo owns them, unless the user explicitly wants a one-off local change.
- If the request names a live path, trace it back to the dotfiles repo before modifying it.
- For a new config unit, decide whether the default `~/.config/<name>` link is correct. If not, add a `.config.toml`.
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
