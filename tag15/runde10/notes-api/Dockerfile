# syntax=docker/dockerfile:1
# Runde 10 – kaputter Stand: Healthcheck wie aus dem Lehrbuch
ARG GO_VERSION=1.27
FROM golang:${GO_VERSION}-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
ARG VERSION=dev
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=${VERSION}" \
    -o /out/notes-api .

FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /out/notes-api /notes-api
USER 65532:65532
EXPOSE 8080
HEALTHCHECK --interval=5s --timeout=2s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1
ENTRYPOINT ["/notes-api"]
