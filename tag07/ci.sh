#!/usr/bin/env bash
# ci.sh – Mini-Pipeline für notes-api: erst testen, dann Multi-Plattform pushen.
# Aufruf aus ~/docker-lab/tag07:  ~/docker-lab/code/tag07/ci.sh [version]
set -euo pipefail
# shellcheck source=/dev/null
source "${LAB:-$HOME/docker-lab}/setup/env.sh"
version="${1:-0.7.0}"
image="$REGISTRY/notes-api:tag07"
platforms="linux/amd64,linux/arm64"

echo "▶ Stage test"
if ! docker build -q --target test -t notes-api:tag07-test notes-api >/dev/null; then
  echo "✘ Tests fehlgeschlagen – kein Push"
  exit 1
fi
echo "✔ Tests grün"

echo "▶ Build $platforms → $image"
docker buildx build --builder "$BUILDER" --platform "$platforms" \
  --build-arg VERSION="$version" -t "$image" --push -q notes-api >/dev/null

got=$(docker buildx imagetools inspect "$image" --format '{{json .Manifest}}' \
  | jq -r '[.manifests[].platform | select(.os != "unknown")
            | "\(.os)/\(.architecture)"] | sort | join(",")')
if [ "$got" = "$platforms" ]; then
  echo "✔ $image enthält $got"
else
  echo "✘ $image enthält nur: ${got:-nichts}"
  exit 1
fi
