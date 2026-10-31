#!/usr/bin/env bash
# find-in-layers.sh IMAGE MUSTER – durchsucht jedes Layer eines Images einzeln.
# Zeigt Dateien, die MUSTER enthalten, und Whiteouts (Löschmarkierungen).
# Exit-Code 0 = kein Treffer, 1 = Treffer.
set -euo pipefail
img=${1:?Aufruf: find-in-layers.sh IMAGE MUSTER}
pat=${2:?Aufruf: find-in-layers.sh IMAGE MUSTER}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

docker save "$img" -o "$tmp/image.tar"
mkdir "$tmp/img"
tar -xf "$tmp/image.tar" -C "$tmp/img"
# manifest.json listet die Layer von unten (Base-Image) nach oben.
layers=$(jq -r --arg i "$img" \
  '(map(select((.RepoTags // []) | index($i))) + .)[0].Layers[]' \
  "$tmp/img/manifest.json")

n=0
hits=0
for layer in $layers; do
  n=$((n + 1))
  dir="$tmp/layer$n"
  mkdir "$dir"
  tar -xf "$tmp/img/$layer" -C "$dir" 2>/dev/null || true
  id=$(basename "$layer")
  while IFS= read -r f; do
    echo "Layer $n (${id:0:12}): ${f#"$dir"/} enthält '$pat'"
    hits=$((hits + 1))
  done < <(grep -rlF -- "$pat" "$dir" 2>/dev/null || true)
  while IFS= read -r w; do
    echo "Layer $n (${id:0:12}): ${w#"$dir"/} (Whiteout: Datei als gelöscht markiert)"
  done < <(find "$dir" -name '.wh.*' ! -name '.wh..wh..opq')
done
echo "$hits Treffer in $n Layern"
[ "$hits" -eq 0 ]
