# syntax=docker/dockerfile:1
# Runde 03 – kaputter Stand: "startet bequem ohne -e"
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
ARG NOTES_API_KEY
ENV NOTES_API_KEY=${NOTES_API_KEY}
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/notes-api"]
