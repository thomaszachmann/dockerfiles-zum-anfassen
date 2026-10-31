#!/usr/bin/env bash
# stoptime.sh <image> – misst docker stop, prüft Graceful Shutdown von notes-api
set -euo pipefail
image="${1:?Aufruf: stoptime.sh <image>}"
name=notes-stoptime

docker rm -f "$name" >/dev/null 2>&1 || true
docker run -d --name "$name" -e NOTES_API_KEY=lab-api-key-123 "$image" >/dev/null
for _ in $(seq 1 50); do
  docker logs "$name" 2>&1 | grep -q 'msg=listening' && break
  sleep 0.2
done

start=$(date +%s)
docker stop "$name" >/dev/null
secs=$(($(date +%s) - start))

if docker logs "$name" 2>&1 | grep -q 'shutdown complete'; then
  result="✔ shutdown complete"
else
  result="✘ kein shutdown complete"
fi
docker rm "$name" >/dev/null
printf '%-16s stop: %2s s  %s\n' "$image" "$secs" "$result"
