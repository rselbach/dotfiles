# Bash experiment

Requires Bash 5.1 or newer (use Homebrew Bash on macOS, not `/bin/bash`).
Shell-specific setup stays here; common aliases and helpers live in
[`../shell/rc.d`](../shell/rc.d) and are also loaded by Zsh.

To try the configuration without installing it:

```sh
bash --rcfile ~/devel/dotfiles/bash/bashrc
```

Install with `make install DIRS=bash`, then run `bash`. `exit` returns to the previous shell; no `chsh` is needed.
The installer backs up existing regular startup files as `*-old`.
Machine-specific overrides belong in `~/.bash.local` and load last.

## Adaptations

- Readline provides Emacs editing, word movement, reverse menu completion,
  case-insensitive completion, and Home/End/Delete bindings.
- Bash completion loads before Carapace and fzf. Atuin, when installed, owns
  Ctrl-R; Up/Down keep ordinary history navigation.
- History uses `~/.bash_history`, appends at every prompt, and does not import
  other terminals' commands. Bash cannot reproduce all Zsh history options;
  duplicate removal applies to the in-memory list, not the entire history file.
- The prompt retains repository-relative paths, Git/JJ information, SSH host,
  a read-only directory indicator, and the success/error arrow. Prompt hooks
  coexist with mise, zoxide, Atuin, and terminal integration.
- `autocd`, `cdspell`, and `dotglob` replace the applicable Zsh options.
  Command spelling correction and automatic directory-stack pushes are omitted.
  Bash's ordinary `pushd`/`popd` remain available.
- Zsh autosuggestions, syntax highlighting, ZLE widgets, and Zsh completions
  are omitted. No additional line-editor framework is installed.
- mise activates once. fnm and pyenv stay lazy; shell integrations request Bash
  output explicitly. Bun's Zsh completion is omitted, but its bin path remains.
- Existing aliases and development, media, token, and forwarding helpers remain.
  Tmux/Zellij layout helpers launch Bash, including interactive Bash for Zellij
  commands that need aliases and functions.
- The Omarchy environment bootstrap and completion are retained without loading
  its competing prompt and duplicate runtime integrations.
- Noninteractive startup runs only the Omarchy environment bootstrap. Scripts
  inherit the interactive environment, but do not load aliases or prompt hooks.

Optional integrations are used only when their executable or script is present.
