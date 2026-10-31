#!/usr/bin/env bash
# check.sh – prüft das Trainingsgelände (✔/✘). Exit-Code = Anzahl Fehler.
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"
fail=0
ok()  { echo "✔ $1"; }
bad() { echo "✘ $1"; fail=$((fail + 1)); }
t()   { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

t "Docker läuft" "docker info"
t "buildx vorhanden" "docker buildx version"
t "Compose v2 vorhanden" "docker compose version"
t "Registry antwortet auf http://$REGISTRY/v2/ (sonst: up.sh)" \
  "curl -sf http://$REGISTRY/v2/"
t "Builder $BUILDER vorhanden (sonst: up.sh)" "docker buildx inspect $BUILDER"
t "hadolint, trivy, jq im PATH" "command -v hadolint && command -v trivy && command -v jq"
t "Demo-Anwendung unter $NOTES" "test -f $NOTES/notes-api/main.go"
t "mindestens 5 GB frei auf dem Mac" \
  "df -k \"\$HOME\" | awk 'NR==2 { exit !(\$4 >= 5 * 1024 * 1024) }'"
exit "$fail"
