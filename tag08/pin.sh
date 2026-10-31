#!/usr/bin/env bash
# pin.sh <Dockerfile> – gibt das Dockerfile mit per Digest gepinnten Base-Images aus.
# Pinnt den Index-Digest (gilt für alle Plattformen). Tag bleibt zur Lesbarkeit stehen.
# Globale ARG-Defaults (ARG X=… vor dem ersten FROM) werden zum Auflösen eingesetzt.
set -euo pipefail
df="${1:?Aufruf: pin.sh <Dockerfile>}"
args=()   # Einträge NAME=WERT (ohne declare -A, läuft auch mit Bash 3.2)
stages=" scratch "

expand() {  # ${X} und $X durch globale ARG-Defaults ersetzen
  local s="$1" kv k v
  for kv in ${args[@]+"${args[@]}"}; do
    k="${kv%%=*}" v="${kv#*=}"
    s="${s//\$\{$k\}/$v}"
    s="${s//\$$k/$v}"
  done
  printf '%s' "$s"
}

seen_from=false
while IFS= read -r line || [ -n "$line" ]; do
  if [[ $line =~ ^ARG[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=([^[:space:]]+) ]] \
     && ! $seen_from; then
    args+=("${BASH_REMATCH[1]}=${BASH_REMATCH[2]}")
  fi
  if [[ $line =~ ^FROM[[:space:]] ]]; then
    seen_from=true
    read -ra w <<<"$line"
    i=1
    while [[ ${w[$i]} == --* ]]; do i=$((i + 1)); done
    ref="${w[$i]}"
    if [[ ${w[$((i + 1))]:-} =~ ^[Aa][Ss]$ ]]; then
      stages+="${w[$((i + 2))]} "
    fi
    if [[ $stages != *" $ref "* && $ref != *@* ]]; then
      real=$(expand "$ref")
      if [[ $real == *'$'* ]]; then
        echo "pin.sh: $ref nicht auflösbar, bleibt ungepinnt" >&2
      else
        digest=$(docker buildx imagetools inspect "$real" \
          --format '{{json .Manifest}}' | jq -r .digest)
        new="$ref@$digest"
        line="${line/"$ref"/$new}"
      fi
    fi
  fi
  printf '%s\n' "$line"
done <"$df"
