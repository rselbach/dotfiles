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


def current_host() -> str:
    return platform.node().lower()


@dataclass
class LinkSpec:
    src: str
    dst: str
    os: str | None = None
    hosts: list[str] | None = None
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
    hosts: list[str] | None = None


@dataclass
class Config:
    target: str | None = None
    skip: bool = False
    links: list[LinkSpec] = field(default_factory=list)
    dirs: list[DirSpec] = field(default_factory=list)
    runs: list[RunSpec] = field(default_factory=list)


def active_links_for(links: list[LinkSpec]) -> list[LinkSpec]:
    """Filter links for the current OS/host with host-specific priority.

    Host-matched links shadow os-matched and universal links that share
    the same src — so a host override fully replaces the default for
    that source path.
    """
    host = current_host()
    os_name = current_os()

    host_matched: list[LinkSpec] = []
    os_matched: list[LinkSpec] = []
    universal: list[LinkSpec] = []

    for link in links:
        if link.hosts:
            if host in [h.lower() for h in link.hosts]:
                host_matched.append(link)
        elif link.os:
            if link.os == os_name:
                os_matched.append(link)
        else:
            universal.append(link)

    # host-specific links shadow others with the same dst
    host_dsts = {link.dst for link in host_matched}
    return (
        [l for l in universal if l.dst not in host_dsts]
        + [l for l in os_matched if l.dst not in host_dsts]
        + host_matched
    )


def active_runs_for(runs: list[RunSpec]) -> list[RunSpec]:
    """Filter run commands for the current OS/host."""
    host = current_host()
    os_name = current_os()
    result: list[RunSpec] = []
    for run in runs:
        if run.hosts:
            if host not in [h.lower() for h in run.hosts]:
                continue
        elif run.os:
            if run.os != os_name:
                continue
        result.append(run)
    return result


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

    # filter links for current OS/host
    active_links = active_links_for(config.links)

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
    for run in active_runs_for(config.runs):
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
    """Check the health of all expected symlinks, derived from configs."""
    ok = 0
    broken = 0
    for name in discover_dirs(DOTFILES):
        config = load_config(DOTFILES / name)
        if config.skip:
            continue
        o, b = check_expected_status(name, config)
        ok += o
        broken += b

    print(f"\n{ok} ok, {broken} broken")


def check_expected_status(name: str, config: Config) -> tuple[int, int]:
    """Check symlink status for a config dir. Returns (ok, broken) counts."""
    config_dir = DOTFILES / name
    active_links = active_links_for(config.links)
    ok = 0
    broken = 0

    def check_symlink(dst: Path, expected_target: Path, label: str = "") -> None:
        nonlocal ok, broken
        if dst.is_symlink() and dst.resolve() == expected_target.resolve():
            suffix = f" -> {pretty(expected_target)}"
            print(f"  ok  {pretty(dst)}{suffix}")
            ok += 1
        else:
            print(f"  BAD {pretty(dst)}{' (missing)' if not dst.exists() else ''}")
            broken += 1

    if config.target is not None:
        check_symlink(resolve_path(config.target), config_dir)
    elif not active_links:
        check_symlink(resolve_path(f"~/.config/{name}"), config_dir)

    for link in active_links:
        pairs = expand_links(link, config_dir)
        for src, dst in pairs:
            if not src.exists() and link.optional:
                continue
            check_symlink(dst, src)

    return ok, broken


# ── CLI ──────────────────────────────────────────────────────────────


def main() -> None:
    args = sys.argv[1:]
    command = args[0] if args else "install"
    rest = args[1:]

    match command:
        case "install":
            names = rest if rest else discover_dirs(DOTFILES)
            manifest = {"symlinks": [], "files": [], "dirs_created": []}
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
