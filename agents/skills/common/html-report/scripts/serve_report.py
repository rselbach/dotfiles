#!/usr/bin/env python3
"""Serve one generated report from a loopback-only HTTP server."""

from __future__ import annotations

import argparse
import functools
import http.server
import sys
from pathlib import Path
from urllib.parse import quote


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    """Serve files without writing routine requests to STDERR."""

    def log_message(self, format: str, *args: object) -> None:
        return


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Serve a generated HTML report on a random loopback port."
    )
    parser.add_argument("report", type=Path, help="path to the report HTML file")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = args.report.resolve()
    if not report.is_file():
        print(f"ERROR: report does not exist: {report}", file=sys.stderr)
        return 1

    handler = functools.partial(QuietHandler, directory=str(report.parent))
    try:
        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    except OSError as error:
        print(f"ERROR: cannot start report server: {error}", file=sys.stderr)
        return 1

    host, port = server.server_address
    print(f"http://{host}:{port}/{quote(report.name)}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
