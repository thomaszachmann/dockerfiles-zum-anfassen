# syntax=docker/dockerfile:1
# Runde 07 – kaputter Stand: aus der CI-Pipeline übernommen
ARG GO_VERSION=1.27
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
ARG VERSION=dev
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w -X main.version=${VERSION}" -o /out/notes-api .

FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /out/notes-api /notes-api
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/notes-api"]
