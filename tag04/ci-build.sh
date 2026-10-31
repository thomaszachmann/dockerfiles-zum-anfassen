#!/usr/bin/env bash
# ci-build.sh <branch> [kontext] – simuliert einen CI-Lauf auf einem frischen Runner:
# eigener, leerer Builder; Cache kommt nur aus der Registry (Branch, sonst main).
set -euo pipefail
# shellcheck source=/dev/null
source "${LAB:-$HOME/docker-lab}/setup/env.sh"
branch="${1:?Aufruf: ci-build.sh <branch> [kontext]}"
ctx="${2:-$LAB/tag04/notes-api}"
tag="${branch//[^a-zA-Z0-9_.-]/-}"          # feature/x -> feature-x
cache="$REGISTRY/notes-api:buildcache"
builder="notes-ci-$$"
log=$(mktemp)
trap 'docker buildx rm "$builder" >/dev/null 2>&1 || true; rm -f "$log"' EXIT

docker buildx create --name "$builder" --driver docker-container \
  --driver-opt network=host >/dev/null
start=$(date +%s)
if ! docker buildx build --builder "$builder" --progress=plain \
    --cache-from "type=registry,ref=$cache-$tag" \
    --cache-from "type=registry,ref=$cache-main" \
    --cache-to "type=registry,ref=$cache-$tag,mode=max,ignore-error=true" \
    --build-arg VERSION="$tag" \
    -t "$REGISTRY/notes-api:$tag" --push "$ctx" >"$log" 2>&1; then
  tail -20 "$log"
  echo "✘ Build $tag fehlgeschlagen"
  exit 1
fi
grep -E '^#[0-9]+ (\[[0-9]+/[0-9]+\]|CACHED|importing cache)|go: downloading' "$log" \
  | grep -vE 'DONE|sha256' || true
echo "✔ $REGISTRY/notes-api:$tag in $(( $(date +%s) - start )) s, Cache $cache-$tag"
