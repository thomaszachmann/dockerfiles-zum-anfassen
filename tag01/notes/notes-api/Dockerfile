# syntax=docker/dockerfile:1
FROM golang:1.27-alpine
WORKDIR /src
COPY . .
RUN go build -o /usr/local/bin/notes-api .
CMD ["notes-api"]
