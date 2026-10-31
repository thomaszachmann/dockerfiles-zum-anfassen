# syntax=docker/dockerfile:1
ARG GO_VERSION=1.27

# base: gemeinsam für test und build, läuft immer auf der Plattform des Builders
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS base
ENV CGO_ENABLED=0
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .

# test: nur mit --target test (CI); gehört nicht zum Final-Image
FROM base AS test
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go vet ./... && go test ./...

# build: Cross-Compile für die Zielplattform, ohne Emulation
FROM base AS build
ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w -X main.version=${VERSION}" \
      -o /out/notes-api .

# final: nur CA-Zertifikate und Binary
FROM scratch AS final
COPY --link --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --link --from=build /out/notes-api /notes-api
LABEL org.opencontainers.image.title="notes-api" \
      org.opencontainers.image.description="Notiz-API aus dem Trainingslager" \
      org.opencontainers.image.source="https://example.com/docker-lab/notes"
EXPOSE 8080
USER 65532:65532
HEALTHCHECK --interval=10s --timeout=2s --start-period=5s --start-interval=1s \
  CMD ["/notes-api", "healthcheck"]
STOPSIGNAL SIGTERM
ENTRYPOINT ["/notes-api"]
