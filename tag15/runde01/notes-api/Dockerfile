# syntax=docker/dockerfile:1
# Runde 01 – kaputter Stand: läuft, ist aber über 1 GB groß
FROM golang:1.27
WORKDIR /src
COPY . .
RUN go build -o /usr/local/bin/notes-api .
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["notes-api"]
