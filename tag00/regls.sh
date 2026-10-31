#!/usr/bin/env bash
# regls.sh – listet alle Repositories, Tags und Digests der lokalen Registry
set -euo pipefail
source "${LAB:-$HOME/docker-lab}/setup/env.sh"
accept='application/vnd.oci.image.index.v1+json'
accept+=',application/vnd.oci.image.manifest.v1+json'
accept+=',application/vnd.docker.distribution.manifest.list.v2+json'
accept+=',application/vnd.docker.distribution.manifest.v2+json'
for repo in $(curl -sf "http://$REGISTRY/v2/_catalog" | jq -r '.repositories[]'); do
  for tag in $(curl -sf "http://$REGISTRY/v2/$repo/tags/list" | jq -r '.tags[]?'); do
    digest=$(curl -sfI -H "Accept: $accept" \
      "http://$REGISTRY/v2/$repo/manifests/$tag" \
      | awk -F': ' 'tolower($1) == "docker-content-digest" { print $2 }' | tr -d '\r')
    printf '%-24s %-10s %s\n' "$repo" "$tag" "${digest:0:19}…"
  done
done
