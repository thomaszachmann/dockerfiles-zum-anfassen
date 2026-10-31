# syntax=docker/dockerfile:1
# Runde 06 – kaputter Stand: Debug-Image mit Shell und Startskript
ARG GO_VERSION=1.27
FROM golang:${GO_VERSION}-alpine
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -o /usr/local/bin/notes-api .
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
