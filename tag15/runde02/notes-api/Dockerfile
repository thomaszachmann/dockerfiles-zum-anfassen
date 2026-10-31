# syntax=docker/dockerfile:1
# Runde 02 – kaputter Stand: jede Änderung lädt alle Module neu
ARG GO_VERSION=1.27
FROM golang:${GO_VERSION}-alpine AS build
WORKDIR /src
COPY . .
RUN go mod download
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=${VERSION}" \
    -o /out/notes-api .

FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /out/notes-api /notes-api
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/notes-api"]
