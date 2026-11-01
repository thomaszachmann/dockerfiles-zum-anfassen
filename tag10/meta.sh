# meta.sh – zum source'n im Git-Projektordner: Build-Metadaten aus dem letzten Commit
# Setzt VERSION, REVISION, CREATED (RFC 3339, UTC) und SOURCE_DATE_EPOCH.
# shellcheck shell=bash
REVISION="$(git rev-parse HEAD)"
VERSION="$(git describe --tags --always --dirty)"
SOURCE_DATE_EPOCH="$(git log -1 --format=%ct)"
CREATED="$(TZ=UTC git log -1 --date=format-local:%Y-%m-%dT%H:%M:%SZ --format=%cd)"
export VERSION REVISION CREATED SOURCE_DATE_EPOCH
