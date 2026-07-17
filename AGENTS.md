# AGENTS.md

Repository-specific notes for agents working in these dotfiles.

## Dotfile installer model

This repo is managed by `install.py`, a small symlink manager. Prefer reading
that file over inferring behavior from existing symlinks.

- Each top-level, non-hidden directory is a config unit. Hidden directories and
  directories whose names start with `__` are ignored.
- Without a `.config.toml`, a config unit is symlinked as a whole directory:
  `./<name>` -> `~/.config/<name>`.
- A `.config.toml` changes that behavior. Supported top-level keys/tables:
  - `skip = true`: do not install that directory.
  - `target = "..."`: symlink the whole directory to this destination instead
    of `~/.config/<name>`.
  - `[[links]]`: explicit per-file/per-directory links.
  - `[[dirs]]`: directories to pre-create before linking.
  - `[[run]]`: post-install commands.
  - `[[watch]]`: destination directories to check for unmanaged files.
- Important: if any `[[links]]` are defined, the default whole-directory link is
  disabled. If all links are filtered out by OS/host, nothing is linked for that
  config unit.

## `.config.toml` details

`[[links]]` fields:

- `src`: source file/dir. Relative paths are resolved inside the config unit;
  absolute paths, `~/...`, and `$...` are expanded as external paths.
- `dst`: destination path. `~` and environment variables are expanded.
- `os`: optional filter; values are normalized platform names like `darwin`,
  `linux`, `windows`.
- `hosts`: optional hostname allow-list; compared case-insensitively against
  `platform.node()`.
- `optional = true`: skip silently when `src` does not exist.
- `secrets = true`: render the source as a template using decrypted
  `secrets.yaml` values instead of symlinking it. Rendered files are written
  with mode `0600`.

Expansion/filtering rules:

- `src = "*"` uses `Path.glob` relative to the config unit.
- `<name>` in `dst` is replaced with the matched source basename.
- Host-specific links win over universal/OS-specific links with the same `dst`.
- OS-specific links only apply when no `hosts` field is present.

`[[dirs]]` fields:

- `path`: directory to create.
- `mode`: optional octal string, for example `"0700"`.

`[[run]]` fields:

- `cmd`: shell command run after links are created.
- `cwd`: optional working directory relative to the config unit.
- `os` / `hosts`: same filtering behavior as links.

`[[watch]]` fields:

- `path`: destination directory to scan during `install` and `status`.
- `ignore`: optional list of filename globs to tolerate.

An entry in a watched directory is considered managed when it is a symlink
resolving into this repo or it is the destination of an active link (covers
`secrets = true` rendered files). Anything else prints an `! unmanaged`
warning; when the directory is the target of a glob link, the warning suggests
the repo directory the file should move to.

## Install behavior to preserve

- Existing non-symlink destinations are moved to `<name>-old` before linking.
  If the `-old` path already exists, it is removed first.
- Incorrect existing symlinks are unlinked and replaced.
- `.install-manifest.json` is rewritten on each install and records symlinks,
  rendered files, and created directories.
- `uninstall` removes recorded symlinks and rendered files from the manifest;
  it does not remove created directories.

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

- This repo uses jj (`.jj/` exists). Do not use git commands for VCS actions.
- Keep changes surgical; do not reformat unrelated config files.
- When adding a new top-level config directory, decide whether the default
  `~/.config/<name>` symlink is correct. If not, add `.config.toml`.
- Use explicit `[[links]]` for files that live outside `~/.config`, host/OS
  variants, globs, or paths that need `<name>` substitution.
- `agents/AGENTS.md` is the shared/global agent instruction file installed into
  tools by configs such as `pi/.config.toml`, `amp/.config.toml`,
  `opencode/.config.toml`, and `claude/.config.toml`. This root file documents
  this dotfiles repo itself.
