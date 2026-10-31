# syntax=docker/dockerfile:1
# Gültigkeitsbereich von ARG und ENV – Demo für Tag 2
ARG GO_VERSION=1.27
FROM golang:${GO_VERSION}-alpine
ARG BUILD_NOTE=ohne-notiz
ENV APP_MODE=lab
RUN echo "GO_VERSION=[${GO_VERSION}] BUILD_NOTE=[${BUILD_NOTE}] APP_MODE=[${APP_MODE}]"
ARG GO_VERSION
RUN echo "nach erneutem ARG: GO_VERSION=[${GO_VERSION}]"
