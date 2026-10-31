#!/usr/bin/env bash
# kontext-check.sh [kontext] – zeigt, was beim Builder vom Build-Kontext ankommt,
# und schlägt fehl, wenn .env, .git, node_modules oder Test-Binaries darin stecken.
set -euo pipefail
ctx="${1:-.}"
[ -d "$ctx" ] || { echo "✘ Kontext $ctx ist kein Ordner"; exit 2; }
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT

# Dockerfile von stdin: kopiert den gefilterten Kontext in ein leeres Image,
# -o type=local schreibt dessen Dateisystem nach $out.
printf 'FROM scratch\nCOPY . /\n' \
  | docker build -q -f - -o "type=local,dest=$out" "$ctx" >/dev/null

echo "Kontext $ctx: $(find "$out" -type f | wc -l | tr -d ' ') Dateien," \
  "$(du -sh "$out" | cut -f1)"
fail=0
for bad in '.env' '.env.*' '.git' 'node_modules' '*.test'; do
  hits=$(cd "$out" && find . -name "$bad" ! -name '.env.example' -prune \
    | tr '\n' ' ')
  if [ -n "$hits" ]; then
    echo "✘ $bad im Kontext: $hits"
    fail=$((fail + 1))
  else
    echo "✔ kein $bad"
  fi
done
exit "$fail"
