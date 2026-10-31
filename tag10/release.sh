#!/usr/bin/env bash
# release.sh – baut notes-api mit Metadaten, SBOM und Provenance als Kandidat in die
# lokale Registry, prüft die SBOM mit trivy und gibt nur bei bestandenem Gate frei:
# Der Release-Tag zeigt dann per Digest auf genau das geprüfte Image.
# Aufruf im Projektordner (Git-Repo): release.sh  (Gegenprobe: GO_VERSION=1.25)
set -euo pipefail
# shellcheck source=/dev/null
source "${LAB:-$HOME/docker-lab}/setup/env.sh"
# shellcheck source=/dev/null
source "$LAB/code/tag10/meta.sh"
repo="$REGISTRY/notes-api"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "▶ baue $repo:$VERSION-rc (Revision ${REVISION:0:12})"
docker buildx build --builder "$BUILDER" --quiet \
  --build-arg GO_VERSION="${GO_VERSION:-1.27}" \
  --build-arg VERSION --build-arg REVISION --build-arg CREATED \
  --sbom=true --provenance=mode=max \
  --metadata-file "$work/meta.json" \
  -t "$repo:$VERSION-rc" --push notes-api >/dev/null
digest="$(jq -r '."containerimage.digest"' "$work/meta.json")"

docker buildx imagetools inspect "$repo@$digest" \
  --format '{{ json .SBOM.SPDX }}' > "$work/sbom.spdx.json"
if ! trivy sbom -q --exit-code 1 --severity HIGH,CRITICAL \
     "$work/sbom.spdx.json"; then
  echo "✘ Gate: HIGH/CRITICAL gefunden – $VERSION nicht freigegeben"
  exit 1
fi

docker buildx imagetools create -t "$repo:$VERSION" "$repo@$digest" >/dev/null
echo "✔ freigegeben: $repo:$VERSION"
echo "  deploye per Digest: $repo@$digest"
