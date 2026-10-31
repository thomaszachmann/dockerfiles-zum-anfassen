"""notes-worker – fasst die Notizen aus notes-api periodisch zusammen.

Umgebung:
  NOTES_API_URL        Basis-URL von notes-api (Standard http://notes-api:8080)
  NOTES_API_KEY_FILE   Datei mit dem API-Key (bevorzugt) oder
  NOTES_API_KEY        API-Key direkt
  INTERVAL             Sekunden zwischen zwei Läufen (Standard 10)
"""

import os
import signal
import sys
import time
from pathlib import Path

import httpx

running = True


def api_key() -> str:
    if path := os.environ.get("NOTES_API_KEY_FILE"):
        return Path(path).read_text().strip()
    if key := os.environ.get("NOTES_API_KEY"):
        return key
    sys.exit("NOTES_API_KEY oder NOTES_API_KEY_FILE fehlt")


def stop(signum, _frame) -> None:
    global running
    print(f"signal {signum} received, stopping", flush=True)
    running = False


def main() -> None:
    url = os.environ.get("NOTES_API_URL", "http://notes-api:8080")
    interval = int(os.environ.get("INTERVAL", "10"))
    key = api_key()
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    print(f"worker started, api={url}, interval={interval}s", flush=True)
    with httpx.Client(base_url=url, headers={"X-API-Key": key}, timeout=5) as client:
        while running:
            try:
                notes = client.get("/notes").raise_for_status().json()
                words = sum(len(n["text"].split()) for n in notes)
                print(f"summary: {len(notes)} notes, {words} words", flush=True)
            except httpx.HTTPError as err:
                print(f"error: {err}", flush=True)
            for _ in range(interval * 10):
                if not running:
                    break
                time.sleep(0.1)
    print("worker stopped", flush=True)
