# syntax=docker/dockerfile:1
# Heredocs in COPY und RUN – Demo für Tag 2
FROM golang:1.27-alpine
ARG VERSION=dev

COPY <<EOT /etc/notes/banner.txt
notes-api ${VERSION} – gebaut im Trainingslager
EOT

COPY <<"EOT" /usr/local/bin/notes-info
#!/bin/sh
echo "Banner: $(cat /etc/notes/banner.txt)"
echo "Laufzeit-User: $(id -u)"
EOT

RUN <<EOT
set -eu
chmod 0755 /usr/local/bin/notes-info
mkdir -p /var/lib/notes
date -u +%Y-%m-%d > /var/lib/notes/built
EOT

CMD ["notes-info"]
