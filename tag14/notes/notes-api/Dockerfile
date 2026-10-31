# syntax=docker/dockerfile:1
# check=error=true
# notes-api – Stand Ende Tag 13
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

# Tag 13: privates Artefakt mit Build-Secret laden. Das Token existiert nur
# während dieses RUN als Umgebungsvariable – in keinem Layer, in keiner History.
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS artifacts
ARG ARTIFACT_URL=http://127.0.0.1:8081
RUN --mount=type=secret,id=artifact_token,env=ARTIFACT_TOKEN,required=true \
    wget -q --header "Authorization: Bearer ${ARTIFACT_TOKEN}" \
      -O /notes-banner.txt "${ARTIFACT_URL}/tools/notes-banner.txt"

FROM base AS build
ARG TARGETOS TARGETARCH VERSION=dev
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w -X main.version=${VERSION}" \
      -o /out/notes-api .

FROM scratch AS final
ARG VERSION=dev REVISION=unknown CREATED=unknown
LABEL org.opencontainers.image.title="notes-api" \
      org.opencontainers.image.description="Notiz-API aus dem Trainingslager" \
      org.opencontainers.image.source="https://example.com/docker-lab/notes" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${CREATED}"
COPY --link --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --link --from=artifacts /notes-banner.txt /usr/share/notes/banner.txt
COPY --link --from=build --chmod=555 /out/notes-api /notes-api
EXPOSE 8080
USER 65532:65532
HEALTHCHECK --interval=10s --timeout=2s --start-period=5s --start-interval=1s \
  CMD ["/notes-api", "healthcheck"]
STOPSIGNAL SIGTERM
ENTRYPOINT ["/notes-api"]
