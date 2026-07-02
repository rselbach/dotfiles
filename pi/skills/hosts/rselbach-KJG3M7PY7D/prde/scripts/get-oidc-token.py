#!/usr/bin/env python3
"""Run an interactive PRDE OIDC authorization-code flow.

Starts a localhost callback listener, opens the browser, exchanges the returned
code for tokens, and writes the token response to a chmod-0600 cache file.
Token values are never printed to stdout.
"""

import base64
import hashlib
import json
import os
import secrets
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ISSUER = "https://rselbach01-ov7lmffx.dev.pedp-remote.hashicorp.services"
CLIENT_ID = "hcp"
CLIENT_SECRET = "hcp"
REDIRECT_URI = "http://localhost:8443/oidc/callback"
AUDIENCE = "https://api.hashicorp.cloud"
SCOPES = "openid offline_access"
TOKEN_PATH = Path.home() / ".cache" / "prde-oidc-token.json"
SUMMARY_PATH = Path("/tmp/prde-oidc-summary.json")


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")


def fetch_json(url: str) -> dict:
    with urllib.request.urlopen(url, timeout=15) as resp:
        return json.loads(resp.read().decode("utf-8"))


def post_form(url: str, values: dict) -> tuple[int, dict | str]:
    body = urllib.parse.urlencode(values).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            payload = resp.read().decode("utf-8")
            try:
                return resp.status, json.loads(payload)
            except json.JSONDecodeError:
                return resp.status, payload
    except urllib.error.HTTPError as err:
        payload = err.read().decode("utf-8", errors="replace")
        try:
            return err.code, json.loads(payload)
        except json.JSONDecodeError:
            return err.code, payload


def redacted_error(body: dict | str) -> dict | str:
    if not isinstance(body, dict):
        return body[:1000]
    result = {}
    for key, value in body.items():
        if key in {"access_token", "id_token", "refresh_token"}:
            result[key] = "<redacted>"
        else:
            result[key] = value
    return result


def summarize_token_response(token_response: dict) -> dict:
    summary = {
        "ok": True,
        "saved_to": str(TOKEN_PATH),
        "token_type": token_response.get("token_type"),
        "expires_in": token_response.get("expires_in"),
        "scope": token_response.get("scope"),
        "has_access_token": bool(token_response.get("access_token")),
        "has_id_token": bool(token_response.get("id_token")),
        "has_refresh_token": bool(token_response.get("refresh_token")),
    }

    id_token = token_response.get("id_token")
    if isinstance(id_token, str) and id_token.count(".") >= 2:
        try:
            claims_part = id_token.split(".")[1]
            padded = claims_part + "=" * (-len(claims_part) % 4)
            claims = json.loads(base64.urlsafe_b64decode(padded.encode("ascii")))
            summary["id_token_issuer"] = claims.get("iss")
            summary["id_token_audience"] = claims.get("aud")
            summary["id_token_expires_at"] = claims.get("exp")
        except Exception as err:  # noqa: BLE001 - summary only; surface error text.
            summary["id_token_decode_error"] = str(err)

    return summary


def main() -> int:
    print("Fetching OIDC discovery document...", flush=True)
    discovery = fetch_json(f"{ISSUER}/.well-known/openid-configuration")
    auth_endpoint = discovery["authorization_endpoint"]
    token_endpoint = discovery["token_endpoint"]
    print(f"issuer={discovery.get('issuer')}", flush=True)
    print(f"authorization_endpoint={auth_endpoint}", flush=True)
    print(f"token_endpoint={token_endpoint}", flush=True)

    state = secrets.token_urlsafe(32)
    verifier = secrets.token_urlsafe(64)
    challenge = b64url(hashlib.sha256(verifier.encode("ascii")).digest())
    result: dict[str, str] = {}

    class CallbackHandler(BaseHTTPRequestHandler):
        def log_message(self, fmt: str, *args: object) -> None:
            print("callback: " + (fmt % args), flush=True)

        def do_GET(self) -> None:  # noqa: N802 - stdlib callback name.
            parsed = urllib.parse.urlparse(self.path)
            if parsed.path != urllib.parse.urlparse(REDIRECT_URI).path:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b"not found")
                return

            params = urllib.parse.parse_qs(parsed.query)
            returned_state = params.get("state", [""])[0]
            if returned_state != state:
                result["error"] = "state_mismatch"
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"State mismatch. You can close this tab.")
                return

            if "error" in params:
                result["error"] = params.get("error", [""])[0]
                result["error_description"] = params.get("error_description", [""])[0]
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"OIDC authorization returned an error. You can close this tab.")
                return

            code = params.get("code", [""])[0]
            if not code:
                result["error"] = "missing_code"
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Missing authorization code. You can close this tab.")
                return

            result["code"] = code
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"PRDE OIDC authorization received. You can close this tab.")

    server = ThreadingHTTPServer(("127.0.0.1", 8443), CallbackHandler)
    server.timeout = 1

    auth_params = {
        "response_type": "code",
        "client_id": CLIENT_ID,
        "redirect_uri": REDIRECT_URI,
        "scope": SCOPES,
        "state": state,
        "audience": AUDIENCE,
        "code_challenge": challenge,
        "code_challenge_method": "S256",
    }
    auth_url = auth_endpoint + "?" + urllib.parse.urlencode(auth_params)

    print(f"Listening on {REDIRECT_URI}", flush=True)
    print("Opening browser for interactive login...", flush=True)
    print(f"If the browser did not open, open this URL manually:\n{auth_url}", flush=True)
    open_result = subprocess.run(["open", auth_url], check=False)
    if open_result.returncode != 0:
        print(f"open command failed with exit {open_result.returncode}; use the URL above.", flush=True)

    deadline = time.monotonic() + 300
    while time.monotonic() < deadline and "code" not in result and "error" not in result:
        server.handle_request()

    server.server_close()

    if "error" in result:
        print(json.dumps({"ok": False, "stage": "authorize", **result}, indent=2), flush=True)
        return 1
    if "code" not in result:
        print(json.dumps({"ok": False, "stage": "authorize", "error": "timed_out_waiting_for_callback"}, indent=2), flush=True)
        return 1

    print("Authorization code received; exchanging for tokens...", flush=True)
    base_payload = {
        "grant_type": "authorization_code",
        "code": result["code"],
        "redirect_uri": REDIRECT_URI,
        "client_id": CLIENT_ID,
        "code_verifier": verifier,
    }

    attempts = [
        ("client_secret_post", {**base_payload, "client_secret": CLIENT_SECRET}),
        ("none", base_payload),
    ]
    last_error: dict | str | None = None
    for method, payload in attempts:
        status, body = post_form(token_endpoint, payload)
        if status >= 200 and status < 300 and isinstance(body, dict) and "access_token" in body:
            TOKEN_PATH.parent.mkdir(parents=True, exist_ok=True)
            tmp_path = TOKEN_PATH.with_suffix(".json.tmp")
            tmp_path.write_text(json.dumps(body, indent=2) + "\n")
            os.chmod(tmp_path, 0o600)
            tmp_path.replace(TOKEN_PATH)
            os.chmod(TOKEN_PATH, 0o600)

            summary = summarize_token_response(body)
            summary["token_exchange_auth_method"] = method
            SUMMARY_PATH.write_text(json.dumps(summary, indent=2) + "\n")
            print(json.dumps(summary, indent=2), flush=True)
            return 0

        last_error = {
            "method": method,
            "status": status,
            "body": redacted_error(body),
        }
        print(json.dumps({"token_exchange_attempt_failed": last_error}, indent=2), flush=True)

    print(json.dumps({"ok": False, "stage": "token", "last_error": last_error}, indent=2), flush=True)
    return 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except OSError as err:
        print(json.dumps({"ok": False, "stage": "startup", "error": str(err)}, indent=2), flush=True)
        raise SystemExit(1)
    except Exception as err:  # noqa: BLE001 - top-level command must surface exact failure.
        print(json.dumps({"ok": False, "stage": "unexpected", "error": repr(err)}, indent=2), flush=True)
        raise SystemExit(1)
