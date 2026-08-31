#!/usr/bin/env python3
"""Render model-bound OpenCode agents used by pstack."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


CAPABILITIES = {
    "worker": {
        "description": "Focused pstack implementation agent bound to {model}",
        "prompt": """You are a focused pstack execution agent.

Complete the assigned task within its stated scope. You may edit files and run
verification when the task calls for it. Do not delegate to another agent.
Return the result, evidence, and any unresolved blocker concisely.
""",
    },
    "reviewer": {
        "description": "Read-only pstack analysis agent bound to {model}",
        "prompt": """You are a read-only pstack analysis and review agent.

Investigate the assigned question using repository evidence. Never modify files
and never delegate to another agent. Return specific findings with file and line
references, or state that no findings were found.
""",
    },
}


def model_slug(model: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", model.lower()).strip("-")


def render_agent(model: str, capability: str) -> str:
    config = CAPABILITIES[capability]
    permission = "  task: deny\n"
    if capability == "reviewer":
        permission = """  bash:
    "*": deny
    "jj status": allow
    "jj diff": allow
    "git status --short": allow
    "git --no-ext-diff diff": allow
    "git --no-ext-diff diff --cached": allow
    "git --no-ext-diff show": allow
    "git log --oneline -10": allow
  edit: deny
  task: deny
"""

    return f"""---
description: {config['description'].format(model=model)}
mode: subagent
model: {model}
temperature: 0.1
permission:
{permission}---

{config['prompt']}"""


def expected_files(models: list[str]) -> dict[str, str]:
    files = {}
    slugs = {}
    for model in models:
        if "/" not in model:
            raise ValueError(f"model must include its provider: {model}")
        slug = model_slug(model)
        if existing := slugs.get(slug):
            raise ValueError(
                f"models produce the same agent slug: {existing}, {model}"
            )
        slugs[slug] = model
        for capability in CAPABILITIES:
            name = f"pstack-{capability}-{slug}.md"
            files[name] = render_agent(model, capability)
    return files


def check(output: Path, files: dict[str, str]) -> int:
    current = {path.name: path for path in output.glob("pstack-*.md")}
    failed = False

    for name, content in files.items():
        path = current.pop(name, None)
        if path is None:
            print(f"missing: {name}", file=sys.stderr)
            failed = True
        elif path.read_text() != content:
            print(f"outdated: {name}", file=sys.stderr)
            failed = True

    for name in sorted(current):
        print(f"stale: {name}", file=sys.stderr)
        failed = True

    return int(failed)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--model", action="append", required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    try:
        files = expected_files(list(dict.fromkeys(args.model)))
    except ValueError as error:
        parser.error(str(error))

    if args.check:
        return check(args.output, files)

    args.output.mkdir(parents=True, exist_ok=True)
    for path in args.output.glob("pstack-*.md"):
        if path.name not in files:
            path.unlink()
    for name, content in files.items():
        (args.output / name).write_text(content)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
