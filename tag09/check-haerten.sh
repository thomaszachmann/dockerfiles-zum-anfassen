#!/usr/bin/env bash
# check-haerten.sh <image> – prüft ein Image auf die Härtungsregeln von Tag 9.
# Exit-Code = Anzahl der ✘. Startet kurz einen Testcontainer notes-check-<pid>.
set -uo pipefail
img="${1:?Aufruf: check-haerten.sh <image>}"
name="notes-check-$$"
fail=0
ok()  { echo "✔ $1"; }
bad() { echo "✘ $1"; fail=$((fail + 1)); }
cleanup() { docker rm -f "$name" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker image inspect "$img" >/dev/null 2>&1 || { echo "✘ Image $img fehlt"; exit 1; }

user=$(docker image inspect -f '{{.Config.User}}' "$img")
if [[ "$user" =~ ^[1-9][0-9]*(:[0-9]+)?$ ]]; then
  ok "USER numerisch und nicht root ($user)"
else
  bad "USER '${user:-<leer>}' ist leer, root oder nicht numerisch"
fi

files=""
docker create --name "$name" "$img" >/dev/null 2>&1 &&
  files=$(docker export "$name" | tar -tf -)
shell=$(grep -E '^(bin|usr/bin)/(ba)?sh$' <<<"$files" | head -1)
if [ -z "$files" ]; then
  bad "Dateisystem nicht exportierbar"
elif [ -n "$shell" ]; then
  bad "Shell im Image: /$shell"
else
  ok "keine Shell im Image"
fi
cleanup

hc=$(docker image inspect -f '{{if .Config.Healthcheck}}ja{{end}}' "$img")
if [ "$hc" = ja ]; then ok "HEALTHCHECK definiert"; else bad "kein HEALTHCHECK"; fi

docker run -d --name "$name" --read-only --cap-drop ALL \
  --security-opt no-new-privileges -e NOTES_API_KEY=lab-api-key-123 \
  "$img" >/dev/null 2>&1
status=missing
for _ in $(seq 1 20); do
  status=$(docker inspect -f \
    '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
    "$name" 2>/dev/null || echo missing)
  [ "$status" = healthy ] && break
  sleep 1
done
if [ "$status" = healthy ] || { [ "$hc" != ja ] && [ "$status" = running ]; }; then
  ok "läuft mit --read-only --cap-drop ALL no-new-privileges ($status)"
else
  bad "startet gehärtet nicht sauber (Status: $status)"
fi
exit "$fail"
