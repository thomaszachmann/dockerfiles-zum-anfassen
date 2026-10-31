"""fetch.py URL ZIEL – lädt URL mit Bearer-Token aus der Datei in TOKEN_FILE."""

import os
import sys
import urllib.request

url, dest = sys.argv[1], sys.argv[2]
token = open(os.environ["TOKEN_FILE"]).read().strip()
req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
with urllib.request.urlopen(req, timeout=5) as resp, open(dest, "wb") as out:
    out.write(resp.read())
print(f"geladen: {dest}")
