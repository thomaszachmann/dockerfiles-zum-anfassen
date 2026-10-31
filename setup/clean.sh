#!/usr/bin/env bash
# clean.sh [--all] – räumt nur Lab-Spuren auf:
#   Container und Images notes-* bzw. $REGISTRY/*, Cache des Builders $BUILDER.
#   --all  zusätzlich Registry (inkl. Volume) und Builder entfernen.
# Nie docker system prune: Das träfe auch fremde Projekte.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"
pat="^(notes-|$REGISTRY/)"

ids=$(docker ps -a --format '{{.ID}} {{.Image}} {{.Names}}' \
  | awk -v p="$pat" '$2 ~ p || $3 ~ /^notes-/ { print $1 }')
[ -n "$ids" ] && docker rm -f $ids >/dev/null
echo "✔ Container entfernt: $(echo $ids | wc -w | tr -d ' ')"

imgs=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "$pat" || true)
[ -n "$imgs" ] && docker rmi -f $imgs >/dev/null
echo "✔ Images entfernt: $(echo $imgs | wc -w | tr -d ' ')"

if docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
  docker buildx prune --builder "$BUILDER" --all --force >/dev/null
  echo "✔ Cache von Builder $BUILDER geleert"
fi

if [ "${1:-}" = --all ]; then
  docker rm -f "$REG_NAME" >/dev/null 2>&1 || true
  docker volume rm "$REG_NAME-data" >/dev/null 2>&1 || true
  docker buildx rm "$BUILDER" >/dev/null 2>&1 || true
  echo "✔ Registry $REG_NAME und Builder $BUILDER entfernt"
fi
