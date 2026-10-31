# syntax=docker/dockerfile:1
# Dockerfile der Challenge (Tag 13): benutzt einen Secret-Mount – und leakt trotzdem.
# in Produktion: @sha256:… pinnen, siehe Tag 8
FROM python:3.13-slim
WORKDIR /app
COPY fetch.py ./
# "Damit die nächsten Schritte das Token auch haben"
RUN --mount=type=secret,id=artifact_token cp /run/secrets/artifact_token /app/.token
RUN TOKEN_FILE=/app/.token python3 fetch.py \
      http://127.0.0.1:8081/tools/notes-banner.txt /app/banner.txt
RUN rm /app/.token
USER 65532:65532
CMD ["cat", "/app/banner.txt"]
