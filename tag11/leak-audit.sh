#!/usr/bin/env bash
# leak-audit.sh IMAGE [MUSTER] – sucht MUSTER in History, Image-Config und Layern.
# Exit-Code = Zahl der Fundorte (0 = sauber).
set -uo pipefail
img=${1:?Aufruf: leak-audit.sh IMAGE [MUSTER]}
pat=${2:-lab-api-key-}
found=0
docker image inspect "$img" >/dev/null 2>&1 || { echo "✘ Image $img fehlt"; exit 99; }
ok()  { echo "✔ $img: $1 sauber"; }
bad() { echo "✘ $img: '$pat' in $1"; found=$((found + 1)); }

if docker history --no-trunc --format '{{.CreatedBy}}' "$img" | grep -qF -- "$pat"; then
  bad "History"
else
  ok "History"
fi
if docker image inspect --format '{{json .Config}}' "$img" | grep -qF -- "$pat"; then
  bad "Image-Config"
else
  ok "Image-Config"
fi
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
docker save "$img" | tar -xf - -C "$tmp"
n=$(for l in $(jq -r '.[0].Layers[]' "$tmp/manifest.json"); do
      tar -xOf "$tmp/$l" 2>/dev/null
    done | grep -acF -- "$pat")
if [ "$n" -gt 0 ]; then
  bad "Layer"
else
  ok "Layer"
fi
exit "$found"
