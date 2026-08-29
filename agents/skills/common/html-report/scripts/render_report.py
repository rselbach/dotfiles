#!/usr/bin/env python3
"""Render structured report data into the bundled self-contained HTML page."""

from __future__ import annotations

import argparse
import html
import json
import sys
import tempfile
from pathlib import Path


VALID_SEVERITIES = {"critical", "high", "medium", "low", "info"}
VALID_STATUSES = {"pass", "fail", "not-run"}


class ReportError(ValueError):
    """An input or template error safe to show to the caller."""


def require_string(data: dict[str, object], key: str) -> str:
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ReportError(f"{key!r} must be a non-empty string")
    return value.strip()


def require_list(data: dict[str, object], key: str) -> list[object]:
    value = data.get(key, [])
    if not isinstance(value, list):
        raise ReportError(f"{key!r} must be a list")
    return value


def validate_report(data: object) -> dict[str, object]:
    if not isinstance(data, dict):
        raise ReportError("report data must be a JSON object")

    require_string(data, "title")
    require_string(data, "subtitle")

    for index, finding in enumerate(require_list(data, "findings"), start=1):
        if not isinstance(finding, dict):
            raise ReportError(f"finding {index} must be an object")
        require_string(finding, "title")
        severity = require_string(finding, "severity")
        if severity not in VALID_SEVERITIES:
            choices = ", ".join(sorted(VALID_SEVERITIES))
            raise ReportError(
                f"finding {index} severity must be one of: {choices}"
            )

    for index, check in enumerate(require_list(data, "verification"), start=1):
        if not isinstance(check, dict):
            raise ReportError(f"verification item {index} must be an object")
        require_string(check, "name")
        status = require_string(check, "status")
        if status not in VALID_STATUSES:
            choices = ", ".join(sorted(VALID_STATUSES))
            raise ReportError(
                f"verification item {index} status must be one of: {choices}"
            )

    return data


def load_report(path: Path) -> dict[str, object]:
    try:
        with path.open(encoding="utf-8") as source:
            return validate_report(json.load(source))
    except OSError as error:
        raise ReportError(f"cannot read {path}: {error}") from error
    except json.JSONDecodeError as error:
        raise ReportError(f"invalid JSON in {path}: {error}") from error


def encode_for_script(data: dict[str, object]) -> str:
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    return (
        payload.replace("<", "\\u003c")
        .replace(">", "\\u003e")
        .replace("&", "\\u0026")
        .replace("\u2028", "\\u2028")
        .replace("\u2029", "\\u2029")
    )


def render(data: dict[str, object], template_path: Path) -> str:
    try:
        template = template_path.read_text(encoding="utf-8")
    except OSError as error:
        raise ReportError(f"cannot read template {template_path}: {error}") from error

    title_token = "__REPORT_TITLE__"
    data_token = "__REPORT_DATA__"
    if template.count(title_token) != 1 or template.count(data_token) != 1:
        raise ReportError("template must contain each report token exactly once")

    return template.replace(
        title_token, html.escape(require_string(data, "title"))
    ).replace(data_token, encode_for_script(data))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render report JSON into a self-contained HTML document."
    )
    parser.add_argument("data", type=Path, help="path to the report JSON file")
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="destination directory; defaults to a fresh temporary directory",
    )
    parser.add_argument(
        "--filename", default="report.html", help="output filename (default: report.html)"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    output_dir = args.output_dir
    if output_dir is None:
        output_dir = Path(tempfile.mkdtemp(prefix="codex-report-"))

    if Path(args.filename).name != args.filename or not args.filename.endswith(".html"):
        print("ERROR: --filename must be a plain .html filename", file=sys.stderr)
        return 2

    try:
        data = load_report(args.data)
        template_path = Path(__file__).resolve().parent.parent / "assets" / "report-template.html"
        document = render(data, template_path)
        output_dir.mkdir(parents=True, exist_ok=True)
        output_path = output_dir / args.filename
        output_path.write_text(document, encoding="utf-8")
    except (OSError, ReportError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(output_path.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
