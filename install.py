#!/usr/bin/env python3
"""Dotfiles installer — convention-over-configuration symlink manager.

Drop a directory in the repo and it gets symlinked to ~/.config/<name>.
Need different behavior? Add a .config.toml with overrides.

Usage:
    python3 install.py              # install all
    python3 install.py install      # same
    python3 install.py install nvim # install one dir
    python3 install.py uninstall    # remove all managed symlinks
    python3 install.py status       # check symlink health
"""

import json
import os
import platform
import shutil
import subprocess
import sys
import tomllib
from dataclasses import dataclass, field
from pathlib import Path

DOTFILES = Path(__file__).resolve().parent
MANIFEST_PATH = DOTFILES / ".install-manifest.json"


# ── helpers ──────────────────────────────────────────────────────────


def current_os() -> str:
    """Return normalized OS name: linux, darwin, or windows."""
    return platform.system().lower()


def resolve_path(s: str) -> Path:
    """Expand ~ and $HOME in a path string."""
    return Path(os.path.expandvars(s)).expanduser()


def backup(path: Path) -> None:
    """If path exists and is NOT a symlink, move it to path-old."""
    if path.exists() and not path.is_symlink():
        dest = path.with_name(path.name + "-old")
        if dest.exists() or dest.is_symlink():
            if dest.is_dir() and not dest.is_symlink():
                shutil.rmtree(dest)
            else:
                dest.unlink()
        path.rename(dest)
        print(f"  ! moved {pretty(path)} -> {pretty(dest)}")


def pretty(p: Path) -> str:
    """Shorten paths under $HOME for display."""
    home = Path.home()
    try:
        return "~/" + str(p.relative_to(home))
    except ValueError:
        return str(p)


# ── config model ─────────────────────────────────────────────────────


@dataclass
class LinkSpec:
    src: str
    dst: str
    os: str | None = None
    optional: bool = False


@dataclass
class DirSpec:
    path: str
    mode: str | None = None


@dataclass
class RunSpec:
    cmd: str
    cwd: str | None = None
    os: str | None = None


@dataclass
class Config:
    target: str | None = None
    skip: bool = False
    links: list[LinkSpec] = field(default_factory=list)
    dirs: list[DirSpec] = field(default_factory=list)
    runs: list[RunSpec] = field(default_factory=list)


def load_config(config_dir: Path) -> Config:
    """Parse .config.toml from a directory, or return default Config."""
    toml_path = config_dir / ".config.toml"
    if not toml_path.exists():
        return Config()

    with open(toml_path, "rb") as f:
        raw = tomllib.load(f)

    return Config(
        target=raw.get("target"),
        skip=raw.get("skip", False),
        links=[LinkSpec(**l) for l in raw.get("links", [])],
        dirs=[DirSpec(**d) for d in raw.get("dirs", [])],
        runs=[RunSpec(**r) for r in raw.get("run", [])],
    )


# ── manifest ─────────────────────────────────────────────────────────


def load_manifest() -> dict:
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH) as f:
            return json.load(f)
    return {"symlinks": [], "files": [], "dirs_created": []}


def save_manifest(manifest: dict) -> None:
    with open(MANIFEST_PATH, "w") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")


def record_symlink(manifest: dict, link: Path) -> None:
    s = str(link)
    if s not in manifest["symlinks"]:
        manifest["symlinks"].append(s)


def record_file(manifest: dict, path: Path) -> None:
    s = str(path)
    if s not in manifest["files"]:
        manifest["files"].append(s)


def record_dir(manifest: dict, path: Path) -> None:
    s = str(path)
    if s not in manifest["dirs_created"]:
        manifest["dirs_created"].append(s)


# ── directory discovery ──────────────────────────────────────────────


def discover_dirs(root: Path) -> list[str]:
    """Return sorted list of config directory names (skip hidden dirs and files)."""
    return sorted(
        p.name
        for p in root.iterdir()
        if p.is_dir()
        and not p.name.startswith(".")
        and not p.name.startswith("__")
    )


# ── glob + <name> expansion ─────────────────────────────────────────


def expand_links(link: LinkSpec, config_dir: Path) -> list[tuple[Path, Path]]:
    """Expand a LinkSpec (possibly with globs and <name>) into (src, dst) pairs."""
    results = []

    if "*" in link.src:
        # glob relative to config_dir
        matched = sorted(config_dir.glob(link.src))
        for src_path in matched:
            if src_path.name == ".config.toml":
                continue
            dst_str = link.dst.replace("<name>", src_path.name)
            results.append((src_path, resolve_path(dst_str)))
    else:
        src_path = config_dir / link.src
        dst_str = link.dst.replace("<name>", src_path.name)
        results.append((src_path, resolve_path(dst_str)))

    return results


# ── install logic ────────────────────────────────────────────────────


def make_symlink(src: Path, dst: Path, manifest: dict) -> None:
    """Create a symlink dst -> src, backing up any existing non-link."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    backup(dst)
    if dst.is_symlink():
        dst.unlink()
    dst.symlink_to(src)
    record_symlink(manifest, dst)
    print(f"  + {pretty(dst)} -> {pretty(src)}")


def install_dir(name: str, config: Config, manifest: dict) -> None:
    """Install a single config directory according to its Config."""
    config_dir = DOTFILES / name

    if config.skip:
        print(f"  - {name}: skipped")
        return

    # pre-create directories
    for d in config.dirs:
        p = resolve_path(d.path)
        p.mkdir(parents=True, exist_ok=True)
        if d.mode:
            p.chmod(int(d.mode, 8))
        record_dir(manifest, p)

    # filter links to those applicable on this OS
    active_links = [l for l in config.links if not l.os or l.os == current_os()]

    # whole-directory symlink
    if config.target is not None:
        dst = resolve_path(config.target)
        make_symlink(config_dir, dst, manifest)
    elif not active_links:
        # default: symlink to ~/.config/<name>
        dst = resolve_path(f"~/.config/{name}")
        dst.parent.mkdir(parents=True, exist_ok=True)
        make_symlink(config_dir, dst, manifest)

    # explicit links
    for link in active_links:
        pairs = expand_links(link, config_dir)
        for src, dst in pairs:
            if not src.exists() and link.optional:
                continue
            if not src.exists():
                print(f"  ? {name}: src missing: {link.src}")
                continue
            make_symlink(src, dst, manifest)

    # post-install commands
    for run in config.runs:
        if run.os and run.os != current_os():
            continue

        cwd = str(config_dir / run.cwd) if run.cwd else str(config_dir)
        print(f"  > {run.cmd}")
        result = subprocess.run(
            run.cmd, shell=True, cwd=cwd,
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            print(f"  ERROR (exit {result.returncode}):")
            if result.stderr:
                for line in result.stderr.strip().splitlines():
                    print(f"    {line}")
            if result.stdout:
                for line in result.stdout.strip().splitlines():
                    print(f"    {line}")


# ── uninstall ────────────────────────────────────────────────────────


def uninstall_from_manifest() -> None:
    """Remove all symlinks and files recorded in the manifest."""
    manifest = load_manifest()

    for s in manifest.get("symlinks", []):
        p = Path(s)
        if p.is_symlink():
            p.unlink()
            print(f"  - {pretty(p)}")
        else:
            print(f"  ~ {pretty(p)} (already gone)")

    for s in manifest.get("files", []):
        p = Path(s)
        if p.exists():
            p.unlink()
            print(f"  - {pretty(p)}")

    # reset manifest
    save_manifest({"symlinks": [], "files": [], "dirs_created": []})
    print("\ndone")


# ── status ───────────────────────────────────────────────────────────


def show_status() -> None:
    """Check the health of all expected symlinks."""
    manifest = load_manifest()
    ok = 0
    broken = 0

    if not manifest.get("symlinks"):
        # no manifest — show what we'd expect based on current configs
        print("no manifest found; showing expected state\n")
        for name in discover_dirs(DOTFILES):
            config = load_config(DOTFILES / name)
            if config.skip:
                continue
            show_expected_status(name, config)
        return

    for s in manifest["symlinks"]:
        p = Path(s)
        if p.is_symlink():
            target = p.resolve()
            print(f"  ok  {pretty(p)} -> {pretty(target)}")
            ok += 1
        else:
            print(f"  BAD {pretty(p)} (missing)")
            broken += 1

    for s in manifest.get("files", []):
        p = Path(s)
        if p.exists():
            print(f"  ok  {pretty(p)}")
            ok += 1
        else:
            print(f"  BAD {pretty(p)} (missing)")
            broken += 1

    print(f"\n{ok} ok, {broken} broken")


def show_expected_status(name: str, config: Config) -> None:
    """Show expected link status when no manifest exists."""
    config_dir = DOTFILES / name
    active_links = [l for l in config.links if not l.os or l.os == current_os()]

    if config.target is not None:
        dst = resolve_path(config.target)
        status = "ok" if (dst.is_symlink() and dst.resolve() == config_dir.resolve()) else "BAD"
        print(f"  {status:3}  {pretty(dst)} -> {name}/")

    elif not active_links:
        dst = resolve_path(f"~/.config/{name}")
        status = "ok" if (dst.is_symlink() and dst.resolve() == config_dir.resolve()) else "BAD"
        print(f"  {status:3}  {pretty(dst)} -> {name}/")

    for link in active_links:
        pairs = expand_links(link, config_dir)
        for src, dst in pairs:
            if not src.exists() and link.optional:
                continue
            status = "ok" if (dst.is_symlink() and dst.resolve() == src.resolve()) else "BAD"
            print(f"  {status:3}  {pretty(dst)}")


# ── CLI ──────────────────────────────────────────────────────────────


def main() -> None:
    args = sys.argv[1:]
    command = args[0] if args else "install"
    rest = args[1:]

    match command:
        case "install":
            names = rest if rest else discover_dirs(DOTFILES)
            manifest = load_manifest()
            for name in names:
                config_dir = DOTFILES / name
                if not config_dir.is_dir():
                    print(f"  ? {name}: directory not found, skipping")
                    continue
                config = load_config(config_dir)
                print(f"[{name}]")
                install_dir(name, config, manifest)
            save_manifest(manifest)
            print("\ndone")

        case "uninstall":
            uninstall_from_manifest()

        case "status":
            show_status()

        case _:
            print(f"unknown command: {command}")
            print("usage: install.py [install [dir...] | uninstall | status]")
            sys.exit(1)


if __name__ == "__main__":
    main()
