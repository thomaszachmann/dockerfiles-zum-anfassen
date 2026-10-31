# syntax=docker/dockerfile:1
ARG GO_VERSION=1.27
FROM golang:${GO_VERSION}-alpine

LABEL org.opencontainers.image.title="notes-api" \
      org.opencontainers.image.description="Notiz-API aus dem Trainingslager" \
      org.opencontainers.image.source="https://example.com/docker-lab/notes"

WORKDIR /src
COPY . .
ARG VERSION=dev
RUN go build -ldflags "-X main.version=${VERSION}" -o /usr/local/bin/notes-api .

EXPOSE 8080
USER 65532:65532
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=10s --timeout=2s --start-period=5s --start-interval=1s \
  CMD ["notes-api", "healthcheck"]
ENTRYPOINT ["notes-api"]
