# dotfiles

Convention-over-configuration symlink manager. Drop a directory in the repo
and it gets symlinked to `~/.config/<name>`. Need different behavior? Add a
`.config.toml`.

## Usage

```sh
make install                    # install all
make install DIRS=nvim          # install one config unit
make status                     # check symlink health
make uninstall                  # remove all managed symlinks
make macos                      # apply macOS defaults
make brew                       # install packages from Brewfile
```

The installer can also be run directly:

```sh
python3 install.py install [dir...]
python3 install.py status
python3 install.py uninstall
```

## How it works

Each top-level directory is a config unit. By default, the entire directory
gets symlinked to `~/.config/<name>`:

```
ghostty/     ->  ~/.config/ghostty
nvim/        ->  ~/.config/nvim
```

### Overrides with `.config.toml`

Add a `.config.toml` inside any directory to customize behavior.

**Custom target** -- symlink the whole directory somewhere else:

```toml
target = "~/.claude"
```

**Skip entirely:**

```toml
skip = true
```

**Dependencies** -- install other config units first:

```toml
depends = ["jj-git-prompt"]
```

Dependencies are transitive, installed only once, and checked for missing units
and cycles before installation starts.

**Explicit links** -- symlink individual files instead of the whole directory:

```toml
[[links]]
src = "settings.json"
dst = "~/.claude/settings.json"

[[links]]
src = "scdaemon.conf"
dst = "~/.gnupg/scdaemon.conf"
optional = true  # skip silently if src doesn't exist
```

**Glob expansion** -- `*` in `src` expands to matching files, `<name>` in
`dst` substitutes the filename:

```toml
[[links]]
src = "*"
dst = "~/.<name>"
```

**Pre-create directories** (with optional permissions):

```toml
[[dirs]]
path = "~/.gnupg"
mode = "0700"
```

**Download files if missing:**

```toml
[[downloads]]
url = "https://example.com/tool-<os>-<arch>"
dst = "~/.local/bin/tool"
mode = "0755"  # optional; defaults to 0755
os = "darwin"  # optional
```

`<os>` expands to `darwin`, `linux`, or `windows`; `<arch>` expands to
`amd64` or `arm64`. Existing destination files are left unchanged. Downloads
are checked by `status` but are not recorded in the manifest or removed by
`uninstall`; delete a destination file to download it again.

**Watch directories** -- warn about files in a destination directory that are
not managed by this repo (checked during `install` and `status`). Useful for
directories whose contents are linked individually, where a file created
directly in the destination would silently escape management:

```toml
[[watch]]
path = "~/.pi/agent/extensions"
ignore = ["*.local.*"]  # optional globs to tolerate
```

**Post-install commands:**

```toml
[[run]]
cmd = "go build -o \"$HOME/bin/nu\" ./cmd/startnu"
cwd = "startnu"
```

### OS filtering

Links, downloads, and run commands can be restricted to an OS (`linux`,
`darwin`, `windows`). Unmatched entries are skipped. Defining links or downloads
disables the default `~/.config/<name>` symlink even if none are active.

```toml
[[links]]
src = "config"
dst = "~/.config/nushell"

[[links]]
src = "config"
dst = "~/Library/Application Support/nushell"
os = "darwin"
```

### Host filtering

Links and run commands can target specific hostnames. Host-specific entries
take priority over OS and universal entries -- if a host-matched link targets
the same destination as another link, the host-matched one wins.

```toml
[[links]]
src = "config"
dst = "~/.config/ghostty/config"

[[links]]
src = "config.omarchy"
dst = "~/.config/ghostty/config"
hosts = ["callisto"]
```

On host `callisto`, the second link replaces the first (same `dst`). On all
other hosts, the first link applies.
