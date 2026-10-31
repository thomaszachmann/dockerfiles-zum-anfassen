#!/usr/bin/env bash
# layers.sh <image> <base-image> – zeigt die eigenen Layer und ihren Anteil am Image
set -euo pipefail
image="${1:?Aufruf: layers.sh <image> <base-image>}"
base="${2:?Aufruf: layers.sh <image> <base-image>}"

# Bytes aus der Angabe von docker history (0B, 12.3kB, 75.4MB, 1.07GB)
to_bytes() {
  awk '{ n = $1 + 0; u = $1; sub(/^[0-9.]+/, "", u)
         f = (u == "kB") ? 1e3 : (u == "MB") ? 1e6 : (u == "GB") ? 1e9 : 1
         print n * f }'
}
sizes() { docker history --format '{{.Size}}' "$1" | to_bytes; }

total_n=$(sizes "$image" | wc -l | tr -d ' ')
base_n=$(sizes "$base" | wc -l | tr -d ' ')
own_n=$((total_n - base_n))
if [ "$own_n" -le 0 ]; then
  echo "✘ $image hat keine eigenen Layer über $base" >&2
  exit 1
fi

# awk statt head: liest alles, damit pipefail nicht über SIGPIPE stolpert
docker history --format '{{.Size}}\t{{.CreatedBy}}' "$image" \
  | awk -v n="$own_n" 'NR <= n { print substr($0, 1, 72) }'
own=$(sizes "$image" | awk -v n="$own_n" 'NR <= n { s += $1 } END { print s + 0 }')
all=$(sizes "$image" | awk '{ s += $1 } END { print s + 0 }')
awk -v o="$own" -v a="$all" -v n="$own_n" 'BEGIN {
  printf "eigene Layer: %d · %.1f MB von %.1f MB (%.0f %%)\n", n, o / 1e6, a / 1e6,
    (a > 0 ? 100 * o / a : 0) }'
