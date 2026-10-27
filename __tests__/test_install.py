import contextlib
import io
import os
import stat
import subprocess
import sys
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


class HostGroupTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.root = Path(self.temp_dir.name).resolve() / "dotfiles"
        self.root.mkdir()
        self.home = self.root.parent / "home"
        self.home.mkdir()
        self.unit = self.root / "community"
        self.unit.mkdir()
        self.global_config = self.root / ".config.toml"
        self.global_config.write_text('[host_groups]\nwork = ["Troy", "Abed"]\n')
        patcher = mock.patch.object(installer, "DOTFILES", self.root)
        patcher.start()
        self.addCleanup(patcher.stop)

    def load_config(self, contents: str) -> installer.Config:
        (self.unit / ".config.toml").write_text(contents)
        return installer.load_config(self.unit)

    def cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        script = self.root / "install.py"
        script.write_text(Path(installer.__file__).read_text())
        return subprocess.run(
            [sys.executable, str(script), *args],
            env={**os.environ, "HOME": str(self.home)},
            capture_output=True,
            text=True,
        )

    def test_expands_groups_in_all_host_fields(self) -> None:
        self.global_config.write_text(
            '[host_groups]\nWork = ["Troy", "Abed"]\n'
            'study = ["Abed", "Annie"]\n'
        )

        config = self.load_config(
            '[[links]]\nsrc = "config"\ndst = "~/config"\n'
            'hosts = ["@WORK", "Jeff", "@study"]\n'
            'exclude_hosts = ["@work"]\n'
            '[[run]]\ncmd = "true"\nhosts = ["@work"]\n'
        )

        self.assertEqual(
            ["Troy", "Abed", "Jeff", "Abed", "Annie"], config.links[0].hosts
        )
        self.assertEqual(["Troy", "Abed"], config.links[0].exclude_hosts)
        self.assertEqual(["Troy", "Abed"], config.runs[0].hosts)

    def test_literal_hosts_work_without_global_config(self) -> None:
        self.global_config.unlink()

        config = self.load_config(
            '[[links]]\nsrc = "config"\ndst = "~/config"\n'
            'hosts = ["Troy"]\nexclude_hosts = ["Abed"]\n'
            '[[run]]\ncmd = "true"\nhosts = []\n'
        )

        self.assertEqual(["Troy"], config.links[0].hosts)
        self.assertEqual(["Abed"], config.links[0].exclude_hosts)
        self.assertEqual([], config.runs[0].hosts)

    def test_rejects_unknown_groups_in_all_host_fields(self) -> None:
        for section, field in [
            ('[[links]]\nsrc = "config"\ndst = "~/config"', "hosts"),
            ('[[links]]\nsrc = "config"\ndst = "~/config"', "exclude_hosts"),
            ('[[run]]\ncmd = "true"', "hosts"),
        ]:
            with self.subTest(section=section, field=field):
                with self.assertRaisesRegex(
                    installer.InstallError, "unknown host group: @missing"
                ) as error:
                    self.load_config(f'{section}\n{field} = ["@missing"]\n')

                self.assertIn(str(self.unit / ".config.toml"), str(error.exception))

    def test_group_reference_without_global_config_is_an_error(self) -> None:
        self.global_config.unlink()

        with self.assertRaisesRegex(installer.InstallError, "unknown host group"):
            self.load_config(
                '[[links]]\nsrc = "config"\ndst = "~/config"\nhosts = ["@work"]\n'
            )

    def test_rejects_invalid_group_definitions(self) -> None:
        cases = {
            "not a table": 'host_groups = ["work"]\n',
            "not a list": '[host_groups]\nwork = "Troy"\n',
            "empty group": '[host_groups]\nwork = []\n',
            "empty member": '[host_groups]\nwork = [""]\n',
            "non-string member": '[host_groups]\nwork = [42]\n',
            "nested group": '[host_groups]\nwork = ["@study"]\n',
            "empty name": '[host_groups]\n"" = ["Troy"]\n',
            "prefixed name": '[host_groups]\n"@work" = ["Troy"]\n',
            "duplicate name": '[host_groups]\nwork = ["Troy"]\nWORK = ["Abed"]\n',
            "invalid TOML": '[host_groups\n',
        }
        for name, contents in cases.items():
            with self.subTest(name=name):
                self.global_config.write_text(contents)

                with self.assertRaises(installer.InstallError) as error:
                    self.load_config('target = "~/community"\n')

                self.assertIn(str(self.global_config), str(error.exception))

    def test_rejects_invalid_host_lists(self) -> None:
        for hosts in ['"@work"', '[42]']:
            with self.subTest(hosts=hosts):
                with self.assertRaises(installer.InstallError):
                    self.load_config(
                        '[[links]]\nsrc = "config"\ndst = "~/config"\n'
                        f'hosts = {hosts}\n'
                    )

    def test_filters_groups_case_insensitively(self) -> None:
        config = self.load_config(
            '[[links]]\nsrc = "work"\ndst = "~/work"\nhosts = ["@work"]\n'
            '[[links]]\nsrc = "personal"\ndst = "~/personal"\n'
            'exclude_hosts = ["@work"]\n'
            '[[run]]\ncmd = "true"\nhosts = ["@work"]\n'
        )
        for host, matches in {"TROY": True, "abed": True, "Jeff": False}.items():
            with self.subTest(host=host):
                with mock.patch.object(installer.platform, "node", return_value=host):
                    work = installer.active_link_specificity(config.links[0])
                    personal = installer.active_link_specificity(config.links[1])
                    runs = installer.active_runs_for(config.runs)

                self.assertEqual(2 if matches else None, work)
                self.assertEqual(None if matches else 0, personal)
                self.assertEqual(config.runs if matches else [], runs)

    def test_bare_group_name_remains_a_literal_hostname(self) -> None:
        config = self.load_config(
            '[[links]]\nsrc = "config"\ndst = "~/config"\nhosts = ["work"]\n'
        )

        with mock.patch.object(installer.platform, "node", return_value="Troy"):
            self.assertIsNone(installer.active_link_specificity(config.links[0]))

        with mock.patch.object(installer.platform, "node", return_value="work"):
            self.assertEqual(2, installer.active_link_specificity(config.links[0]))

    def test_group_links_keep_hostname_priority(self) -> None:
        config = self.load_config(
            '[[links]]\nsrc = "default"\ndst = "~/config"\n'
            '[[links]]\nsrc = "os"\ndst = "~/config"\nos = "linux"\n'
            '[[links]]\nsrc = "work"\ndst = "~/config"\nhosts = ["@work"]\n'
            '[[links]]\nsrc = "troy"\ndst = "~/config"\nhosts = ["Troy"]\n'
        )
        for links, want in [
            (config.links[:3], "work"),
            (config.links, "troy"),
            ([*config.links[:2], config.links[3], config.links[2]], "work"),
        ]:
            with self.subTest(want=want, links=len(links)):
                with (
                    mock.patch.object(installer.platform, "node", return_value="Troy"),
                    mock.patch.object(
                        installer.platform, "system", return_value="Linux"
                    ),
                ):
                    entries = installer.active_link_entries_for(links, self.unit)

                self.assertEqual([self.unit / want], [entry.src for entry in entries])

    def test_cli_installs_checks_and_uninstalls_group_links(self) -> None:
        self.global_config.write_text(
            f'[host_groups]\nwork = ["{installer.current_host()}"]\n'
        )
        for name in ["default", "work", "personal"]:
            (self.unit / name).write_text(name)
        self.load_config(
            '[[links]]\nsrc = "default"\ndst = "~/.community"\n'
            '[[links]]\nsrc = "work"\ndst = "~/.community"\nhosts = ["@work"]\n'
            '[[links]]\nsrc = "personal"\ndst = "~/.personal"\n'
            'exclude_hosts = ["@work"]\n'
            '[[run]]\ncmd = "touch group-ran"\nhosts = ["@work"]\n'
            '[[run]]\ncmd = "touch other-ran"\nhosts = ["CityCollege"]\n'
        )

        result = self.cli("install", "community")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertTrue((self.home / ".community").is_symlink())
        self.assertEqual(self.unit / "work", (self.home / ".community").resolve())
        self.assertFalse((self.home / ".personal").exists())
        self.assertTrue((self.unit / "group-ran").is_file())
        self.assertFalse((self.unit / "other-ran").exists())

        result = self.cli("status")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("1 ok, 0 broken", result.stdout)

        result = self.cli("uninstall")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertFalse((self.home / ".community").is_symlink())

    def test_cli_reports_config_errors_without_installing(self) -> None:
        (self.unit / ".config.toml").write_text(
            '[[links]]\nsrc = "config"\ndst = "~/.community"\n'
            'hosts = ["@missing"]\n'
        )
        for command in ["install", "status"]:
            with self.subTest(command=command):
                result = self.cli(command)

                self.assertEqual(1, result.returncode)
                self.assertIn("ERROR:", result.stderr)
                self.assertIn("unknown host group: @missing", result.stderr)
                self.assertNotIn("Traceback", result.stderr)
                self.assertEqual([], list(self.home.iterdir()))
                self.assertFalse((self.root / ".install-manifest.json").exists())


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


class LinkTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def test_glob_skips_excluded_names(self) -> None:
        for name in ["abed", "synced", "troy"]:
            (self.root / "skills" / name).mkdir(parents=True)
        (self.root / ".config.toml").write_text(
            "[[links]]\n"
            'src = "skills/*"\n'
            'dst = "/greendale/<name>"\n'
            'exclude = ["synced"]\n'
        )

        config = installer.load_config(self.root)
        result = installer.expand_links(config.links[0], self.root)

        self.assertEqual(
            [
                (self.root / "skills" / "abed", Path("/greendale/abed")),
                (self.root / "skills" / "troy", Path("/greendale/troy")),
            ],
            result,
        )


if __name__ == "__main__":
    unittest.main()
