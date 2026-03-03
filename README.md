# dotfiles

Convention-over-configuration symlink manager. Drop a directory in the repo
and it gets symlinked to `~/.config/<name>`. Need different behavior? Add a
`.config.toml`.

## Usage

```
python3 install.py              # install all
python3 install.py install nvim # install one dir
python3 install.py status       # check symlink health
python3 install.py uninstall    # remove all managed symlinks
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

**Post-install commands:**

```toml
[[run]]
cmd = "go build -o \"$HOME/bin/nu\" ./cmd/startnu"
cwd = "startnu"
```

### OS filtering

Links and run commands can be restricted to an OS (`linux`, `darwin`,
`windows`). Unmatched entries are skipped; if no links match the current OS,
the default `~/.config/<name>` symlink applies.

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
