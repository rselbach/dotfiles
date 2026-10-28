import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ZSH = shutil.which("zsh")
AGENT_MARKERS = {
    "CLAUDECODE": "1",
    "CODEX_THREAD_ID": "greendale",
    "OPENCODE": "1",
    "PI_CODING_AGENT": "true",
}
OPTIONS = (
    'print -r -- "${options[nomatch]} ${options[equals]} '
    '${options[shwordsplit]} ${options[interactivecomments]}"'
)


@unittest.skipUnless(ZSH, "zsh is not installed")
class ZshEnvTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.home = Path(self.temp_dir.name)
        source = Path(__file__).resolve().parents[1] / "zsh" / "zshenv"
        (self.home / ".zshenv").symlink_to(source)

    def run_zsh(
        self, command: str, markers: dict[str, str], interactive: bool = False
    ) -> str:
        env = {key: value for key, value in os.environ.items() if key not in AGENT_MARKERS}
        env.update(HOME=str(self.home), ZDOTDIR=str(self.home))
        env.update(markers)
        args = [ZSH, "-d", "-u"]
        if interactive:
            args.append("-i")
        result = subprocess.run(
            [*args, "-c", command],
            env=env,
            cwd=self.home,
            capture_output=True,
            text=True,
            timeout=5,
        )
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("", result.stderr)
        return result.stdout.strip()

    def test_agent_commands_accept_literal_globs_and_equals(self) -> None:
        command = (
            f"{OPTIONS}\n"
            "printf '%s\\n' --include=*.ts =====\n"
            "value='Troy Barnes'; printf '<%s>\\n' $value"
        )
        for marker, value in AGENT_MARKERS.items():
            with self.subTest(agent=marker):
                output = self.run_zsh(command, {marker: value})
                self.assertEqual(
                    "off off off off\n--include=*.ts\n=====\n<Troy Barnes>", output
                )

    def test_interactive_agent_shells_keep_defaults(self) -> None:
        for marker, value in AGENT_MARKERS.items():
            with self.subTest(agent=marker):
                output = self.run_zsh(OPTIONS, {marker: value}, interactive=True)
                self.assertEqual("on on off off", output)

    def test_unmarked_shells_keep_defaults(self) -> None:
        for markers in [{}, dict.fromkeys(AGENT_MARKERS, "")]:
            with self.subTest(markers=markers):
                output = self.run_zsh(OPTIONS, markers)
                self.assertEqual("on on off off", output)
