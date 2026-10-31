# syntax=docker/dockerfile:1
# check=error=true
ARG GO_VERSION=1.27

# in Produktion: @sha256:… pinnen, siehe Tag 8
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS base
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .

FROM base AS test
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go vet ./... && go test ./...

FROM base AS build
ARG TARGETOS TARGETARCH
ARG VERSION=dev
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w -X main.version=${VERSION}" \
      -o /out/notes-api .

FROM scratch AS final
# Dateien gehören root; das Binary ist nur les- und ausführbar. Kein --chmod an
# Dateien in neuen Ordnern: Es gälte auch für die Ordner (siehe Drill 2).
COPY --link --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --link --from=build --chmod=555 /out/notes-api /notes-api
ARG VERSION=dev
ARG REVISION=unknown
ARG CREATED=unknown
LABEL org.opencontainers.image.title="notes-api" \
      org.opencontainers.image.description="Notiz-API aus dem Trainingslager" \
      org.opencontainers.image.source="https://example.com/docker-lab/notes" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${CREATED}"
EXPOSE 8080
USER 65532:65532
HEALTHCHECK --interval=10s --timeout=2s --start-period=5s --start-interval=1s \
  CMD ["/notes-api", "healthcheck"]
STOPSIGNAL SIGTERM
ENTRYPOINT ["/notes-api"]
