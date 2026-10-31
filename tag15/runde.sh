#!/usr/bin/env bash
# runde.sh NN|challenge – legt ~/docker-lab/tag15/rundeNN mit dem kaputten Stand an.
# Basis ist immer die unveränderte Demo-Anwendung aus code/notes; darüber kommt
# der kaputte Stand aus code/tag15/rundeNN. Ein vorhandener Ordner wird ersetzt.
set -euo pipefail
# shellcheck source=/dev/null
source "${LAB:-$HOME/docker-lab}/setup/env.sh"
nr="${1:?Aufruf: runde.sh 01..10 oder runde.sh challenge}"
case "$nr" in
  challenge) name=challenge ;;
  0[1-9] | 10) name="runde$nr" ;;
  *) echo "✘ unbekannte Runde: $nr" >&2; exit 1 ;;
esac
src="$LAB/code/tag15/$name"
dst="$LAB/tag15/$name"
[ -d "$src" ] || { echo "✘ $src fehlt" >&2; exit 1; }
rm -rf "$dst"
mkdir -p "$dst"
cp -R "$LAB/code/notes/." "$dst/"
cp -R "$src/." "$dst/"
echo "✔ $dst bereit"
