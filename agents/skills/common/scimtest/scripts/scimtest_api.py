#!/usr/bin/env python3
"""Call a running scimtest instance through its authenticated loopback API."""

import argparse
import ipaddress
import json
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, ProxyHandler, Request, build_opener


class NoRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def read_instance(state_file):
    state_path = Path(state_file).expanduser().resolve()
    lock_path = Path(str(state_path) + ".lock")
    try:
        instance = json.loads(lock_path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ValueError(
            f"No instance lock at {lock_path}; start the intended app first"
        ) from error
    if not isinstance(instance, dict):
        raise ValueError("Instance lock must contain a JSON object")
    origin = instance.get("url")
    token = instance.get("token")
    if not isinstance(origin, str) or not isinstance(token, str) or not token:
        raise ValueError("Instance lock must contain a URL and nonempty token")
    parsed = urlsplit(origin)
    try:
        loopback = ipaddress.ip_address(parsed.hostname or "").is_loopback
    except ValueError:
        loopback = False
    if (
        parsed.scheme != "http"
        or not loopback
        or parsed.port is None
        or parsed.username is not None
        or parsed.password is not None
        or parsed.path not in ("", "/")
        or parsed.query
        or parsed.fragment
    ):
        raise ValueError("Instance URL must be an HTTP loopback IP and port")
    return origin.rstrip("/"), token


def read_body(args):
    raw = args.json
    if args.data_file == "-":
        raw = sys.stdin.read()
    elif args.data_file is not None:
        raw = Path(args.data_file).expanduser().read_text(encoding="utf-8")
    if raw is None:
        return None
    body = json.loads(raw)
    if not isinstance(body, dict):
        raise ValueError("Request body must be a JSON object")
    return json.dumps(body).encode("utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--state-file", required=True,
        help="State database of the intended running instance",
    )
    parser.add_argument("method", choices=("GET", "POST", "PATCH", "PUT", "DELETE"))
    parser.add_argument(
        "path", help="Path relative to /api/v1, such as /status or /environments",
    )
    body = parser.add_mutually_exclusive_group()
    body.add_argument("--json", help="JSON request object")
    body.add_argument("--data-file", help="JSON request file, or - for standard input")
    args = parser.parse_args()

    try:
        parsed_path = urlsplit(args.path)
        if (
            not args.path.startswith("/")
            or args.path.startswith("//")
            or parsed_path.scheme
            or parsed_path.netloc
            or parsed_path.fragment
        ):
            raise ValueError("Use an API-relative path beginning with /, not a URL")
        origin, token = read_instance(args.state_file)
        request = Request(
            origin + "/api/v1" + ("" if args.path == "/" else args.path),
            data=read_body(args),
            method=args.method,
            headers={
                "Accept": "application/json",
                "Content-Type": "application/json",
                "X-Scimtest-Instance-Token": token,
            },
        )
        opener = build_opener(ProxyHandler({}), NoRedirects())
        with opener.open(request, timeout=30) as response:
            if response.status == 204:
                return 0
            if response.headers.get_content_type() != "application/json":
                raise ValueError(
                    "Expected a JSON API response; check the instance and scimtest version"
                )
            result = json.load(response)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 0
    except HTTPError as error:
        with error:
            detail = error.read().decode("utf-8", errors="replace").strip()
        print(f"HTTP {error.code}: {detail or error.reason}", file=sys.stderr)
    except URLError as error:
        print(f"Cannot reach the local instance: {error.reason}", file=sys.stderr)
    except (OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
