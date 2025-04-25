# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Test Commands
- Execute setup scripts: `./setup-[arch|debian|mac].sh`
- Run specific setup module: `SETUP_DIR=$(pwd) source setup.d/XX-name-[os|all]`
- Verify script: `bash -n script_name.sh` to check syntax without execution
- No formal test process; scripts are standalone shell scripts

## Code Style Guidelines
- Shell scripts: Use POSIX-compatible shell syntax (sh/bash)
- File naming: OS-specific files use `-[os]` suffix (e.g., `setup-mac.sh`)
- Script modules in `setup.d/` follow `XX-name-[os|all]` pattern (XX = priority number)
- Environment variables: Use UPPERCASE for script-wide variables
- Functions: Use lowercase snake_case for function names
- Conditional execution: Check for OS type before running commands
- Error handling: Verify commands succeed with exit code checks where critical
- Variable expansion: Prefer ${VAR} over $VAR for clarity
- Quote variables: Always quote variable expansions to handle spaces
- Config files: Store in `configs/` directory with appropriate naming
- Shell style: Use double brackets [[ ]] for conditionals when appropriate
- Command paths: Use absolute paths when necessary for reliability

