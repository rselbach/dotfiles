# Shared shell configuration

`rc.d/*.sh` contains configuration shared by Bash and Zsh. These files use
syntax supported by both shells; they are not intended for POSIX `sh`.

The numbered entry points in `bash/rc.d` and `zsh/rc.d` source each shared
fragment at its original position in startup. Paths are relative to the repo
directories resolved by the shell loaders, so no additional installation link
is needed. This directory is skipped by the dotfile installer.

Each shell provides `_path_add` during environment setup. The tmux and Zellij
entry points select their shell executable before loading the shared helpers.
Zellij also receives `_zellij_shell_flags`: `-lic` for Bash and `-lc` for Zsh.
These settings remain available for helpers called after startup.

Keep prompts, completion, history, keybindings, and shell-specific tool
initialization in their respective shell directories.
