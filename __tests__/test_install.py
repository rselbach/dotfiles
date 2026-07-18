import contextlib
import io
import os
import stat
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


if __name__ == "__main__":
    unittest.main()
