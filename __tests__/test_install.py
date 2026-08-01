import contextlib
import io
import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import install as installer


class DependencyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def make_unit(self, name: str, config: str = "") -> None:
        unit = self.root / name
        unit.mkdir()
        if config:
            (unit / ".config.toml").write_text(config)

    def test_resolves_shared_dependency_once_before_dependents(self) -> None:
        self.make_unit("jj-git-prompt")
        self.make_unit("bash", 'depends = ["jj-git-prompt"]\n')
        self.make_unit("zsh", 'depends = ["jj-git-prompt"]\n')

        with mock.patch.object(installer, "DOTFILES", self.root):
            result = installer.resolve_install_names(["bash", "zsh"])

        self.assertEqual(["jj-git-prompt", "bash", "zsh"], result)

    def test_rejects_dependency_cycle(self) -> None:
        self.make_unit("troy", 'depends = ["abed"]\n')
        self.make_unit("abed", 'depends = ["troy"]\n')

        with mock.patch.object(installer, "DOTFILES", self.root):
            with self.assertRaisesRegex(
                installer.InstallError,
                "dependency cycle: troy -> abed -> troy",
            ):
                installer.resolve_install_names(["troy"])

    def test_rejects_missing_dependency(self) -> None:
        self.make_unit("troy", 'depends = ["abed"]\n')

        with mock.patch.object(installer, "DOTFILES", self.root):
            with self.assertRaisesRegex(
                installer.InstallError,
                "config unit not found: abed",
            ):
                installer.resolve_install_names(["troy"])


class DownloadTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.home = self.root / "home"
        self.home.mkdir()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def test_expands_normalized_platform_names(self) -> None:
        with (
            mock.patch.object(installer.platform, "system", return_value="Darwin"),
            mock.patch.object(installer.platform, "machine", return_value="x86_64"),
        ):
            result = installer.expand_download_url(
                "https://example.test/tool-<os>-<arch>"
            )

        self.assertEqual("https://example.test/tool-darwin-amd64", result)

    def test_filters_downloads_by_os(self) -> None:
        downloads = [
            installer.DownloadSpec(
                "https://example.test/darwin",
                "~/tool",
                os="darwin",
            ),
            installer.DownloadSpec(
                "https://example.test/linux",
                "~/tool",
                os="linux",
            ),
        ]

        with mock.patch.object(installer.platform, "system", return_value="Darwin"):
            result = installer.active_downloads_for(downloads)

        self.assertEqual([downloads[0]], result)

    def test_downloads_missing_file_and_skips_existing_file(self) -> None:
        source = self.root / "source"
        source.write_bytes(b"Greendale Human Being")
        download = installer.DownloadSpec(
            url=source.as_uri(),
            dst="~/.local/bin/community",
        )

        with mock.patch.dict(os.environ, {"HOME": str(self.home)}):
            installer.install_download(download)
            source.unlink()
            installer.install_download(download)

        dst = self.home / ".local/bin/community"
        self.assertEqual(b"Greendale Human Being", dst.read_bytes())
        self.assertEqual(0o755, stat.S_IMODE(dst.stat().st_mode))

    def test_failed_download_leaves_destination_missing(self) -> None:
        source = self.root / "missing"
        download = installer.DownloadSpec(
            url=source.as_uri(),
            dst="~/.local/bin/community",
        )

        with mock.patch.dict(os.environ, {"HOME": str(self.home)}):
            with self.assertRaisesRegex(
                installer.InstallError,
                "failed to download",
            ):
                installer.install_download(download)

        dst = self.home / ".local/bin/community"
        self.assertFalse(dst.exists())
        self.assertEqual([], list(dst.parent.glob(".community.*")))

    def test_rejects_truncated_response(self) -> None:
        response = io.BytesIO(b"Troy and Abed")
        response.headers = {"Content-Length": "100"}
        download = installer.DownloadSpec(
            url="https://example.test/community",
            dst="~/.local/bin/community",
        )

        with (
            mock.patch.dict(os.environ, {"HOME": str(self.home)}),
            mock.patch.object(
                installer.urllib.request,
                "urlopen",
                return_value=response,
            ),
        ):
            with self.assertRaisesRegex(
                installer.InstallError,
                "incomplete download",
            ):
                installer.install_download(download)

        dst = self.home / ".local/bin/community"
        self.assertFalse(dst.exists())

    def test_download_unit_has_no_default_link_or_manifest_entry(self) -> None:
        source = self.root / "source"
        source.write_bytes(b"Greendale Human Being")
        unit = self.root / "community"
        unit.mkdir()
        config = installer.Config(
            downloads=[
                installer.DownloadSpec(
                    url=source.as_uri(),
                    dst="~/.local/bin/community",
                )
            ]
        )
        manifest = {"symlinks": [], "files": [], "dirs_created": []}

        with (
            mock.patch.dict(os.environ, {"HOME": str(self.home)}),
            mock.patch.object(installer, "DOTFILES", self.root),
        ):
            installer.install_dir("community", config, manifest)

        self.assertEqual(
            {"symlinks": [], "files": [], "dirs_created": []},
            manifest,
        )
        self.assertFalse((self.home / ".config/community").exists())

    def test_status_checks_only_for_file_presence(self) -> None:
        config = installer.Config(
            downloads=[
                installer.DownloadSpec(
                    url="https://example.test/community",
                    dst="~/.local/bin/community",
                )
            ]
        )

        with (
            mock.patch.dict(os.environ, {"HOME": str(self.home)}),
            contextlib.redirect_stdout(io.StringIO()),
        ):
            self.assertEqual((0, 1), installer.check_expected_status("test", config))
            dst = self.home / ".local/bin/community"
            dst.parent.mkdir(parents=True)
            dst.write_bytes(b"Ben Chang")
            self.assertEqual((1, 0), installer.check_expected_status("test", config))


class RepositoryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.source = self.root / "source"
        self.git("init", "-b", "main", str(self.source))
        self.git("-C", str(self.source), "config", "user.name", "Troy Barnes")
        self.git(
            "-C",
            str(self.source),
            "config",
            "user.email",
            "troy@greendale.test",
        )
        self.first_commit = self.commit("Study room reserved")
        self.git("-C", str(self.source), "tag", "v1.0.0")

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def git(self, *args: str) -> str:
        result = subprocess.run(
            ["git", *args],
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout.strip()

    def commit(self, contents: str) -> str:
        (self.source / "bulletin.txt").write_text(contents)
        self.git("-C", str(self.source), "add", "bulletin.txt")
        self.git("-C", str(self.source), "commit", "-m", contents)
        return self.git("-C", str(self.source), "rev-parse", "HEAD")

    def repository(self, name: str, ref: str) -> installer.RepositorySpec:
        return installer.RepositorySpec(
            url=str(self.source),
            dst=str(self.root / name),
            ref=ref,
        )

    def test_loads_repository_config(self) -> None:
        unit = self.root / "community"
        unit.mkdir()
        (unit / ".config.toml").write_text(
            '[[repositories]]\n'
            'url = "https://example.test/greendale.git"\n'
            'dst = "~/.local/share/greendale"\n'
            'ref = "main"\n'
        )

        config = installer.load_config(unit)

        self.assertEqual(
            [
                installer.RepositorySpec(
                    url="https://example.test/greendale.git",
                    dst="~/.local/share/greendale",
                    ref="main",
                )
            ],
            config.repositories,
        )

    def test_checks_out_branch_and_fast_forwards(self) -> None:
        repository = self.repository("greendale", "main")
        installer.install_repository(repository)

        self.assertEqual(
            "main",
            self.git("-C", repository.dst, "branch", "--show-current"),
        )
        self.commit("Paintball rescheduled")
        installer.install_repository(repository)

        self.assertEqual(
            "Paintball rescheduled",
            (Path(repository.dst) / "bulletin.txt").read_text(),
        )

    def test_does_not_overwrite_a_divergent_branch(self) -> None:
        repository = self.repository("greendale", "main")
        installer.install_repository(repository)
        self.git("-C", repository.dst, "config", "user.name", "Abed Nadir")
        self.git(
            "-C",
            repository.dst,
            "config",
            "user.email",
            "abed@greendale.test",
        )
        checkout_file = Path(repository.dst) / "bulletin.txt"
        checkout_file.write_text("Six seasons and a movie")
        self.git("-C", repository.dst, "add", "bulletin.txt")
        self.git(
            "-C",
            repository.dst,
            "commit",
            "-m",
            "Document the plan",
        )
        local_commit = self.git("-C", repository.dst, "rev-parse", "HEAD")
        self.commit("City College attacks")

        with self.assertRaises(installer.InstallError):
            installer.install_repository(repository)

        self.assertEqual(
            local_commit,
            self.git("-C", repository.dst, "rev-parse", "HEAD"),
        )
        self.assertEqual("Six seasons and a movie", checkout_file.read_text())

    def test_checks_out_tags_and_commit_shas_detached(self) -> None:
        for name, ref in {
            "by-tag": "v1.0.0",
            "by-sha": self.first_commit,
        }.items():
            with self.subTest(ref=ref):
                repository = self.repository(name, ref)
                installer.install_repository(repository)

                self.assertEqual(
                    self.first_commit,
                    self.git("-C", repository.dst, "rev-parse", "HEAD"),
                )
                self.assertEqual(
                    "",
                    self.git("-C", repository.dst, "branch", "--show-current"),
                )

    def test_rejects_existing_checkout_with_wrong_origin(self) -> None:
        repository = self.repository("greendale", "main")
        installer.install_repository(repository)
        repository.url = str(self.root / "city-college")

        with self.assertRaisesRegex(
            installer.InstallError,
            "origin does not match",
        ):
            installer.install_repository(repository)

    def test_repository_unit_has_no_default_link_or_manifest_entry(self) -> None:
        unit = self.root / "community"
        unit.mkdir()
        repository = self.repository("greendale", "main")
        config = installer.Config(repositories=[repository])
        manifest = {"symlinks": [], "files": [], "dirs_created": []}

        with (
            mock.patch.dict(os.environ, {"HOME": str(self.home)}),
            mock.patch.object(installer, "DOTFILES", self.root),
        ):
            installer.install_dir("community", config, manifest)

        self.assertEqual(
            {"symlinks": [], "files": [], "dirs_created": []},
            manifest,
        )
        self.assertFalse((self.home / ".config/community").exists())

    def test_status_checks_repository_ref(self) -> None:
        repository = self.repository("greendale", "main")
        config = installer.Config(repositories=[repository])
        installer.install_repository(repository)

        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(
                (1, 0),
                installer.check_expected_status("community", config),
            )
            self.commit("Save Greendale")
            self.git("-C", repository.dst, "fetch", "origin")
            self.assertEqual(
                (0, 1),
                installer.check_expected_status("community", config),
            )
            installer.install_repository(repository)
            self.assertEqual(
                (1, 0),
                installer.check_expected_status("community", config),
            )
            self.git(
                "-C",
                repository.dst,
                "checkout",
                "--detach",
                self.first_commit,
            )
            self.assertEqual(
                (0, 1),
                installer.check_expected_status("community", config),
            )


if __name__ == "__main__":
    unittest.main()
