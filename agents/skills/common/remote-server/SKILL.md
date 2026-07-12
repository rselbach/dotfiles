---
name: remote-server
description: Use ONLY when the user asks to run, inspect, diagnose, deploy, or manage commands on the remote server ssh.rselbach.com over SSH. Do not use for local workspace tasks.
---

# Remote Server

Use this skill when the user asks to run something on the remote server.

## Connection

- SSH target: `ssh.rselbach.com`
- Authentication: use the local default SSH key. Passwordless login is expected.
- Default command shape:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 ssh.rselbach.com '<remote command>'
```

If SSH authentication fails, report the exact error and stop. Do not retry with
password prompts, copied keys, or credential changes unless Roberto explicitly
asks for that.

## Running Commands

- Prefer one non-interactive SSH command per remote action.
- Start by discovering context with commands such as `pwd`, `hostname`, `uname`,
  `ls`, or service-specific status commands. Do not assume the remote directory.
- Keep commands read-only until the requested task clearly requires changes.
- Do not run destructive commands, package installs, service restarts, database
  migrations, or `sudo` unless Roberto explicitly asks.
- For remote project work, `cd` into the target directory inside the SSH command:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 ssh.rselbach.com 'cd ~/app && git status --short'
```

- For multi-step shell logic, run a remote shell with strict failure handling:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 ssh.rselbach.com 'bash -lc '\''set -euo pipefail; cd ~/app; ./script.sh'\'''
```

## Long-Running Work

If a remote command may run longer than a couple of minutes, prefer `tmux` on the
remote server when available:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 ssh.rselbach.com 'tmux new-session -d -s opencode-job "cd ~/app && ./long-job.sh"'
ssh -o BatchMode=yes -o ConnectTimeout=10 ssh.rselbach.com 'tmux capture-pane -pt opencode-job'
```

If a command runs longer than five minutes, stop, capture the latest available
output, and ask Roberto before retrying or extending the timeout.

## File Access

- The local Read/Edit/Glob/Grep tools operate on the local machine, not the
  remote server.
- Use SSH commands for remote inspection.
- Use `scp` or `rsync` only when Roberto asks to move files between local and
  remote machines.
- Do not copy secrets, SSH keys, tokens, or private config out of the remote
  server unless Roberto explicitly asks.

## Failure Handling

- Surface exact command failures, including stderr and exit behavior.
- Do not hide partial failures behind summaries.
- If a command changes remote state, run a relevant verification command after
  the change and report both the change and verification result.
