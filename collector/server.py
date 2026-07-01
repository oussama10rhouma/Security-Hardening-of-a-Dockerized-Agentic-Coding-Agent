#!/usr/bin/env python3
"""Local collector for the security TP (no third party is ever contacted).

Two modes (env INSPECT):
  INSPECT=0  -> naive collector: logs whatever it receives to /data/exfil.log.
  INSPECT=1  -> content-inspecting defensive gateway: decodes query params,
                scans for secret-looking patterns and REFUSES (HTTP 403) any
                request that carries a secret. This is the bonus mitigation
                (a MITM-style egress inspector).
"""
import base64
import datetime
import http.server
import os
import re
import socketserver
import urllib.parse

LOG = "/data/exfil.log"
PORT = int(os.environ.get("PORT", "9000"))
INSPECT = os.environ.get("INSPECT", "0") == "1"
SECRET_RE = re.compile(os.environ.get("SECRET_PATTERN", r"sk-DEMO|FAKE_API_KEY|sk-[A-Za-z0-9]"))


def log(msg: str) -> None:
    os.makedirs("/data", exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
    line = f"{stamp} {msg}"
    with open(LOG, "a", encoding="utf-8") as fh:
        fh.write(line + "\n")
    print(line, flush=True)


def candidate_strings(path: str, body: str):
    """Yield the raw request plus best-effort decoded query parameters."""
    yield path
    yield body
    q = urllib.parse.urlparse(path).query
    for _k, vals in urllib.parse.parse_qs(q).items():
        for v in vals:
            yield v
            try:
                yield base64.b64decode(v + "===").decode("utf-8", "replace")
            except Exception:
                pass


def carries_secret(path: str, body: str) -> bool:
    return any(SECRET_RE.search(s or "") for s in candidate_strings(path, body))


class Handler(http.server.BaseHTTPRequestHandler):
    def _body(self) -> str:
        n = int(self.headers.get("Content-Length", 0) or 0)
        return self.rfile.read(n).decode("utf-8", "replace") if n else ""

    def _respond(self, code: int, payload: bytes) -> None:
        self.send_response(code)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _handle(self, method: str) -> None:
        body = self._body()
        # ignore container health probes (GET /) so the evidence log stays clean
        if method == "GET" and self.path in ("/", "/health"):
            self._respond(200, b"ok")
            return
        if INSPECT and carries_secret(self.path, body):
            log(f"BLOCKED {method} {self.path} :: content inspection refused a secret")
            self._respond(403, b"blocked")
            return
        log(f"EXFIL {method} {self.path} :: {body}")
        self._respond(200, b"ok")

    def do_POST(self) -> None:  # noqa: N802
        self._handle("POST")

    def do_GET(self) -> None:  # noqa: N802
        self._handle("GET")

    def log_message(self, *_args) -> None:
        return


if __name__ == "__main__":
    log(f"collector listening on :{PORT} (INSPECT={'on' if INSPECT else 'off'})")
    with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
        httpd.serve_forever()
