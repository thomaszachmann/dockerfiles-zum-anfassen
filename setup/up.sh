#!/usr/bin/env bash
# up.sh – startet lokale Registry und buildx-Builder (idempotent)
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"

if ! docker inspect "$REG_NAME" >/dev/null 2>&1; then
  docker run -d --name "$REG_NAME" --restart unless-stopped \
    --label lab=docker-lab-infra \
    -p "127.0.0.1:$REG_PORT:5000" \
    -v "$REG_NAME-data:/var/lib/registry" \
    registry:3.0.0 >/dev/null
elif [ "$(docker inspect -f '{{.State.Running}}' "$REG_NAME")" != true ]; then
  docker start "$REG_NAME" >/dev/null
fi
for _ in $(seq 1 20); do
  curl -sf "http://$REGISTRY/v2/" >/dev/null && break
  sleep 0.5
done
echo "✔ Registry $REG_NAME auf http://$REGISTRY"

if ! docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
  docker buildx create --name "$BUILDER" --driver docker-container \
    --driver-opt network=host --bootstrap >/dev/null 2>&1
fi
echo "✔ Builder $BUILDER (docker-container, network=host)"
