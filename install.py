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

import fnmatch
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

DOTFILES = Path(__file__).resolve().parent
MANIFEST_PATH = DOTFILES / ".install-manifest.json"


# ── helpers ──────────────────────────────────────────────────────────


def current_os() -> str:
    """Return normalized OS name: linux, darwin, or windows."""
    return platform.system().lower()


def current_arch() -> str:
    """Return a normalized release architecture name."""
    machine = platform.machine().lower()
    aliases = {
        "aarch64": "arm64",
        "arm64": "arm64",
        "amd64": "amd64",
        "x86_64": "amd64",
    }
    if machine not in aliases:
        raise InstallError(f"unsupported architecture: {machine}")
    return aliases[machine]


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


class InstallError(Exception):
    """A configuration or installation error safe to show to the user."""


def current_host() -> str:
    return platform.node().lower()


@dataclass
class LinkSpec:
    src: str
    dst: str
    os: str | None = None
    hosts: list[str] | None = None
    exclude_hosts: list[str] | None = None
    optional: bool = False
    secrets: bool = False


@dataclass
class DirSpec:
    path: str
    mode: str | None = None


@dataclass
class WatchSpec:
    path: str
    ignore: list[str] = field(default_factory=list)


@dataclass
class RunSpec:
    cmd: str
    cwd: str | None = None
    os: str | None = None
    hosts: list[str] | None = None


@dataclass
class DownloadSpec:
    url: str
    dst: str
    mode: str = "0755"
    os: str | None = None


@dataclass
class Config:
    target: str | None = None
    skip: bool = False
    depends: list[str] = field(default_factory=list)
    links: list[LinkSpec] = field(default_factory=list)
    dirs: list[DirSpec] = field(default_factory=list)
    downloads: list[DownloadSpec] = field(default_factory=list)
    runs: list[RunSpec] = field(default_factory=list)
    watches: list[WatchSpec] = field(default_factory=list)


@dataclass
class ActiveLink:
    link: LinkSpec
    src: Path
    dst: Path
    specificity: int
    index: int


def active_link_specificity(link: LinkSpec) -> int | None:
    """Return link priority for this host, or None when inactive."""
    host = current_host()
    os_name = current_os()

    if link.exclude_hosts and host in [h.lower() for h in link.exclude_hosts]:
        return None
    if link.hosts:
        if host in [h.lower() for h in link.hosts]:
            return 2
        return None
    if link.os:
        if link.os == os_name:
            return 1
        return None
    return 0


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


def active_downloads_for(downloads: list[DownloadSpec]) -> list[DownloadSpec]:
    """Filter downloads for the current OS."""
    os_name = current_os()
    return [download for download in downloads if download.os in (None, os_name)]


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
        depends=raw.get("depends", []),
        links=[LinkSpec(**l) for l in raw.get("links", [])],
        dirs=[DirSpec(**d) for d in raw.get("dirs", [])],
        downloads=[DownloadSpec(**d) for d in raw.get("downloads", [])],
        runs=[RunSpec(**r) for r in raw.get("run", [])],
        watches=[WatchSpec(**w) for w in raw.get("watch", [])],
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


def resolve_install_names(names: list[str]) -> list[str]:
    """Return config units in dependency-first order."""
    resolved: list[str] = []
    visited: set[str] = set()
    visiting: list[str] = []

    def visit(name: str) -> None:
        if name in visited:
            return
        if name in visiting:
            start = visiting.index(name)
            cycle = visiting[start:] + [name]
            raise InstallError(f"dependency cycle: {' -> '.join(cycle)}")

        config_dir = DOTFILES / name
        if not config_dir.is_dir():
            raise InstallError(f"config unit not found: {name}")

        visiting.append(name)
        config = load_config(config_dir)
        if not config.skip:
            for dependency in config.depends:
                visit(dependency)
        visiting.pop()
        visited.add(name)
        resolved.append(name)

    for name in names:
        visit(name)
    return resolved


# ── secrets ──────────────────────────────────────────────────────────

_secrets_cache: dict | None = None


def load_secrets() -> dict:
    """Decrypt secrets.yaml via sops (cached for the run)."""
    global _secrets_cache
    if _secrets_cache is not None:
        return _secrets_cache

    secrets_path = DOTFILES / "secrets.yaml"
    if not secrets_path.exists():
        print("ERROR: secrets.yaml not found but a link has secrets=true")
        sys.exit(1)

    try:
        result = subprocess.run(
            ["sops", "-d", "--output-type", "json", str(secrets_path)],
            capture_output=True, text=True,
        )
    except FileNotFoundError:
        print("ERROR: sops is not installed")
        sys.exit(1)

    if result.returncode != 0:
        print(f"ERROR: failed to decrypt secrets.yaml:\n  {result.stderr.strip()}")
        sys.exit(1)

    _secrets_cache = json.loads(result.stdout)
    return _secrets_cache


def render_template(src: Path, secrets: dict) -> str:
    """Replace {{key}} placeholders with values from secrets dict."""
    template = src.read_text()

    def replacer(match: re.Match) -> str:
        key = match.group(1).strip()
        if key not in secrets:
            print(f"  ERROR: secret '{key}' not found in secrets.yaml")
            sys.exit(1)
        return str(secrets[key])

    return re.sub(r"\{\{(\s*\w+\s*)\}\}", replacer, template)


# ── glob + <name> expansion ─────────────────────────────────────────


def is_absolute_src(src: str) -> bool:
    """True when src should be resolved as an absolute path, not relative to config_dir."""
    return src.startswith(("/", "~/", "$"))


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
    elif is_absolute_src(link.src):
        src_path = resolve_path(link.src)
        dst_str = link.dst.replace("<name>", src_path.name)
        results.append((src_path, resolve_path(dst_str)))
    else:
        src_path = config_dir / link.src
        dst_str = link.dst.replace("<name>", src_path.name)
        results.append((src_path, resolve_path(dst_str)))

    return results


def active_link_entries_for(
    links: list[LinkSpec],
    config_dir: Path,
) -> list[ActiveLink]:
    """Return active expanded links, with host/os entries overriding defaults."""
    entries: list[ActiveLink] = []

    for index, link in enumerate(links):
        specificity = active_link_specificity(link)
        if specificity is None:
            continue

        for src, dst in expand_links(link, config_dir):
            if link.optional and not src.exists():
                continue
            entries.append(ActiveLink(link, src, dst, specificity, index))

    winners: dict[str, ActiveLink] = {}
    for entry in entries:
        key = str(entry.dst)
        previous = winners.get(key)
        if previous is None:
            winners[key] = entry
            continue
        if (entry.specificity, entry.index) >= (
            previous.specificity,
            previous.index,
        ):
            winners[key] = entry

    return [entry for entry in entries if winners[str(entry.dst)] is entry]


# ── install logic ────────────────────────────────────────────────────


def ensure_dir(path: Path, manifest: dict) -> None:
    """Create a real directory, replacing an existing symlink if needed."""
    if path.is_symlink():
        path.unlink()
        print(f"  ! replaced {pretty(path)} symlink with directory")
    path.mkdir(parents=True, exist_ok=True)
    record_dir(manifest, path)


def make_symlink(src: Path, dst: Path, manifest: dict) -> None:
    """Create a symlink dst -> src, skipping if already correct."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink() and dst.resolve() == src.resolve():
        record_symlink(manifest, dst)
        return
    backup(dst)
    if dst.is_symlink():
        dst.unlink()
    dst.symlink_to(src)
    record_symlink(manifest, dst)
    print(f"  + {pretty(dst)} -> {pretty(src)}")


def render_file(src: Path, dst: Path, manifest: dict) -> None:
    """Render a template with secrets and write to dst (mode 0600)."""
    secrets = load_secrets()
    rendered = render_template(src, secrets)

    # skip if already up to date
    if dst.exists() and not dst.is_symlink() and dst.read_text() == rendered:
        record_file(manifest, dst)
        return

    dst.parent.mkdir(parents=True, exist_ok=True)
    backup(dst)
    if dst.exists() or dst.is_symlink():
        dst.unlink()
    dst.write_text(rendered)
    dst.chmod(0o600)
    record_file(manifest, dst)
    print(f"  + {pretty(dst)} (rendered with secrets)")


def expand_download_url(url: str) -> str:
    """Substitute normalized platform placeholders in a download URL."""
    return url.replace("<os>", current_os()).replace("<arch>", current_arch())


def install_download(download: DownloadSpec) -> None:
    """Download a missing file and atomically install it at its destination."""
    dst = resolve_path(download.dst)
    if dst.is_file():
        return
    if dst.exists() or dst.is_symlink():
        raise InstallError(f"download destination is not a file: {pretty(dst)}")

    try:
        mode = int(download.mode, 8)
    except ValueError as err:
        raise InstallError(f"invalid download mode: {download.mode}") from err

    url = expand_download_url(download.url)
    temp_path: Path | None = None
    try:
        dst.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(
            prefix=f".{dst.name}.",
            dir=dst.parent,
            delete=False,
        ) as output:
            temp_path = Path(output.name)
            with urllib.request.urlopen(url, timeout=60) as response:
                content_length = response.headers.get("Content-Length")
                bytes_written = 0
                while chunk := response.read(1024 * 1024):
                    output.write(chunk)
                    bytes_written += len(chunk)
                if (
                    content_length is not None
                    and bytes_written != int(content_length)
                ):
                    raise InstallError(
                        f"incomplete download: received {bytes_written} of "
                        f"{content_length} bytes"
                    )
        temp_path.chmod(mode)
        try:
            os.link(temp_path, dst)
        except FileExistsError as err:
            if dst.is_file():
                return
            raise InstallError(
                f"download destination is not a file: {pretty(dst)}"
            ) from err
    except InstallError:
        raise
    except Exception as err:
        raise InstallError(f"failed to download {url}: {err}") from err
    finally:
        if temp_path is not None:
            temp_path.unlink(missing_ok=True)

    print(f"  + {pretty(dst)} (downloaded)")


def install_dir(name: str, config: Config, manifest: dict) -> None:
    """Install a single config directory according to its Config."""
    config_dir = DOTFILES / name

    if config.skip:
        print(f"  - {name}: skipped")
        return

    # pre-create directories
    for d in config.dirs:
        p = resolve_path(d.path)
        ensure_dir(p, manifest)
        if d.mode:
            p.chmod(int(d.mode, 8))

    # whole-directory symlink
    if config.target is not None:
        dst = resolve_path(config.target)
        make_symlink(config_dir, dst, manifest)
    elif not config.links and not config.downloads:
        # default: symlink to ~/.config/<name>
        # only applies when no links or downloads were defined at all. if
        # links were filtered out for this host/os, skip the default.
        dst = resolve_path(f"~/.config/{name}")
        dst.parent.mkdir(parents=True, exist_ok=True)
        make_symlink(config_dir, dst, manifest)

    # explicit links
    for entry in active_link_entries_for(config.links, config_dir):
        link = entry.link
        src = entry.src
        dst = entry.dst
        if not src.exists():
            print(f"  ? {name}: src missing: {link.src}")
            continue
        if link.secrets:
            render_file(src, dst, manifest)
        else:
            make_symlink(src, dst, manifest)

    for download in active_downloads_for(config.downloads):
        install_download(download)

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


# ── watch ────────────────────────────────────────────────────────────


def glob_link_dirs(config: Config, config_dir: Path) -> list[tuple[Path, Path]]:
    """(dst_dir, src_dir) pairs for active glob links, used for move hints."""
    pairs = []
    for link in config.links:
        if active_link_specificity(link) is None:
            continue
        if "*" not in link.src or "<name>" not in link.dst:
            continue
        dst_dir = resolve_path(link.dst.replace("<name>", "x")).parent
        src_dir = (config_dir / link.src).parent
        pairs.append((dst_dir, src_dir))
    return pairs


def check_watches(name: str, config: Config) -> int:
    """Warn about unmanaged entries in watched directories. Returns count."""
    config_dir = DOTFILES / name
    expected_dsts = {
        entry.dst for entry in active_link_entries_for(config.links, config_dir)
    }
    hint_dirs = glob_link_dirs(config, config_dir)
    warnings = 0

    for watch in config.watches:
        root = resolve_path(watch.path)
        if not root.is_dir():
            continue
        for entry in sorted(root.iterdir()):
            if entry.is_symlink() and entry.resolve().is_relative_to(DOTFILES):
                continue
            if entry in expected_dsts:
                continue
            if any(fnmatch.fnmatch(entry.name, pat) for pat in watch.ignore):
                continue
            hints = [
                str(src.relative_to(DOTFILES)) + "/"
                for dst_dir, src in hint_dirs
                if dst_dir == root
            ]
            hint = f" (move to {' or '.join(hints)}?)" if hints else ""
            print(f"  ! unmanaged: {pretty(entry)}{hint}")
            warnings += 1

    return warnings


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
    unmanaged = 0
    for name in discover_dirs(DOTFILES):
        config = load_config(DOTFILES / name)
        if config.skip:
            continue
        o, b = check_expected_status(name, config)
        ok += o
        broken += b
        unmanaged += check_watches(name, config)

    summary = f"\n{ok} ok, {broken} broken"
    if unmanaged:
        summary += f", {unmanaged} unmanaged"
    print(summary)


def check_expected_status(name: str, config: Config) -> tuple[int, int]:
    """Check symlink status for a config dir. Returns (ok, broken) counts."""
    config_dir = DOTFILES / name
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
    elif not config.links and not config.downloads:
        check_symlink(resolve_path(f"~/.config/{name}"), config_dir)

    for entry in active_link_entries_for(config.links, config_dir):
        check_symlink(entry.dst, entry.src)

    for download in active_downloads_for(config.downloads):
        dst = resolve_path(download.dst)
        if dst.is_file():
            print(f"  ok  {pretty(dst)}")
            ok += 1
        else:
            suffix = " (missing)" if not dst.exists() else ""
            print(f"  BAD {pretty(dst)}{suffix}")
            broken += 1

    return ok, broken


# ── CLI ──────────────────────────────────────────────────────────────


def main() -> None:
    args = sys.argv[1:]
    command = args[0] if args else "install"
    rest = args[1:]

    match command:
        case "install":
            requested = rest if rest else discover_dirs(DOTFILES)
            try:
                names = resolve_install_names(requested)
            except InstallError as err:
                print(f"ERROR: {err}")
                sys.exit(1)
            manifest = {"symlinks": [], "files": [], "dirs_created": []}
            for name in names:
                config = load_config(DOTFILES / name)
                print(f"[{name}]")
                try:
                    install_dir(name, config, manifest)
                except InstallError as err:
                    print(f"  ERROR: {err}")
                    sys.exit(1)
                if not config.skip:
                    check_watches(name, config)
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
