# AGENTS.md

Repository-specific notes for agents working in these dotfiles.

## Dotfile installer

Edit managed configuration at its repo source. When ownership, rendering, or
installation behavior is unclear, consult the relevant `.config.toml` and
[`installer.md`](agents/skills/common/dotfiles-repo/references/installer.md).
Read the relevant parts of `install.py` when those leave a question unresolved.

## Common commands

Use the repo `Makefile` when possible:

```sh
make status
make install
make install DIRS=nvim
make uninstall
```

Equivalent direct commands:

```sh
python3 install.py status
python3 install.py install [dir...]
python3 install.py uninstall
```

## Editing guidance

- Detect the checkout's VCS using the shared instructions.
- Keep changes surgical; do not reformat unrelated config files.
- When adding a new top-level config directory, decide whether the default
  `~/.config/<name>` symlink is correct. If not, add `.config.toml`.
- Use explicit `[[links]]` for files that live outside `~/.config`, host/OS
  variants, globs, or paths that need `<name>` substitution.
- `agents/AGENTS.md` is the shared/global agent instruction file installed into
  tools by configs such as `pi/.config.toml`, `amp/.config.toml`,
  `opencode/.config.toml`, and `claude/.config.toml`. This root file documents
  this dotfiles repo itself.
