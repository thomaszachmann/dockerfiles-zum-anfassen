#!/usr/bin/env bash
# scan-image.sh IMAGE MUSTER – sucht MUSTER in History, Config und allen Layern
# eines lokalen Images. Exit-Code = Anzahl Fundstellen. Nur mit Lab-Werten benutzen!
set -euo pipefail
img="${1:?Aufruf: scan-image.sh IMAGE MUSTER}"
pat="${2:?Aufruf: scan-image.sh IMAGE MUSTER}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

hits=0
if docker history --no-trunc --format '{{.CreatedBy}}' "$img" | grep -qF -- "$pat"; then
  echo "✘ Treffer in docker history"
  hits=$((hits + 1))
fi

docker save "$img" -o "$tmp/image.tar"
mkdir "$tmp/x"
tar -xf "$tmp/image.tar" -C "$tmp/x"
while IFS= read -r -d '' f; do
  if gzip -t "$f" 2>/dev/null; then
    found=$(gzip -dc "$f" | grep -acF -- "$pat" || true)
  else
    found=$(grep -acF -- "$pat" "$f" || true)
  fi
  if [ "$found" -gt 0 ]; then
    echo "✘ Treffer in ${f#"$tmp/x/"}"
    hits=$((hits + 1))
  fi
done < <(find "$tmp/x" -type f -print0)

[ "$hits" -eq 0 ] && echo "✔ Muster nicht gefunden in $img"
exit "$hits"
