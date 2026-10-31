#!/bin/sh
# Startskript: kurzes Banner, dann den Server starten
echo "notes-api startet als UID $(id -u)"
notes-api "$@"
echo "notes-api beendet"
