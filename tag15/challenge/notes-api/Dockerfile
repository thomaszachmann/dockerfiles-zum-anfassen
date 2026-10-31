# syntax=docker/dockerfile:1
# Challenge – kaputter Stand: sechs Desaster in einer Datei
ARG GO_VERSION=1.27
FROM golang:${GO_VERSION}-alpine AS build
WORKDIR /src
COPY . .
RUN go mod download
RUN CGO_ENABLED=0 GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /out/notes-api .

FROM scratch
COPY --from=build /out/notes-api /notes-api
ARG NOTES_API_KEY
ENV NOTES_API_KEY=${NOTES_API_KEY}
EXPOSE 8080
HEALTHCHECK CMD wget -qO- http://localhost:8080/healthz || exit 1
ENTRYPOINT ["/notes-api"]
