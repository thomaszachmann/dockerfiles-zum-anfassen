"""artifact-server – simuliert ein privates Artefakt-Repository (Tag 13).

GET /healthz                  -> ok (ohne Token)
GET /tools/notes-banner.txt   -> nur mit Header "Authorization: Bearer <Token>"

Token aus ARTIFACT_TOKEN_FILE (bevorzugt) oder ARTIFACT_TOKEN. Nur Lab-Werte!
"""

import hmac
import os
import signal
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

FILES = Path(__file__).parent / "files"
ROUTES = {"/tools/notes-banner.txt": FILES / "notes-banner.txt"}


def load_token() -> str:
    if path := os.environ.get("ARTIFACT_TOKEN_FILE"):
        return Path(path).read_text().strip()
    if token := os.environ.get("ARTIFACT_TOKEN"):
        return token.strip()
    sys.exit("ARTIFACT_TOKEN oder ARTIFACT_TOKEN_FILE fehlt")


class Handler(BaseHTTPRequestHandler):
    token = ""

    def send(self, code: int, body: bytes, ctype: str = "text/plain") -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        if code == 401:
            self.send_header("WWW-Authenticate", 'Bearer realm="notes-artifacts"')
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802 (Name von http.server vorgegeben)
        if self.path == "/healthz":
            self.send(200, b"ok\n")
            return
        got = self.headers.get("Authorization", "").encode()
        want = f"Bearer {self.token}".encode()
        if not hmac.compare_digest(got, want):
            self.send(401, b"unauthorized\n")
            return
        target = ROUTES.get(self.path)
        if target is None:
            self.send(404, b"not found\n")
            return
        self.send(200, target.read_bytes())

    def log_message(self, fmt: str, *args) -> None:
        # Nur Methode, Pfad und Status loggen – nie Header (dort steht das Token).
        if self.path == "/healthz":
            return
        print(f"{self.address_string()} {fmt % args}", flush=True)


def main() -> None:
    Handler.token = load_token()
    port = int(os.environ.get("PORT", "8081"))
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    print(f"artifact-server listening on :{port}", flush=True)
    try:
        server.serve_forever()
    finally:
        server.server_close()
        print("artifact-server stopped", flush=True)


if __name__ == "__main__":
    main()
