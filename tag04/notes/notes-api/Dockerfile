# syntax=docker/dockerfile:1
# Stand Ende Tag 4: Abhängigkeiten zuerst, Cache-Mounts für Module und Build-Cache.
ARG GO_VERSION=1.27
FROM golang:${GO_VERSION}-alpine
LABEL org.opencontainers.image.title="notes-api" \
      org.opencontainers.image.description="Notiz-API aus dem Trainingslager" \
      org.opencontainers.image.source="https://example.com/docker-lab/notes"
WORKDIR /src
# 1. Nur die Abhängigkeitsliste – ändert sich selten, Layer bleibt im Cache
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download
# 2. Quellcode – ändert sich ständig, invalidiert nur noch das Folgende
COPY . .
# ARG erst hier: Ein neuer VERSION-Wert invalidiert nur den Build-Schritt
ARG VERSION=dev
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -ldflags "-X main.version=${VERSION}" -o /usr/local/bin/notes-api .
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=2s --start-period=5s --start-interval=1s \
  CMD ["notes-api", "healthcheck"]
STOPSIGNAL SIGTERM
USER 65532:65532
ENTRYPOINT ["notes-api"]
