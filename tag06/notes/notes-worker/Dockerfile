# syntax=docker/dockerfile:1
# notes-worker, Stand Tag 6: uv im build-Stage, nur die .venv im Laufzeit-Image
ARG PYTHON_VERSION=3.13

# in Produktion: @sha256:… pinnen, siehe Tag 8
FROM python:${PYTHON_VERSION}-slim AS build
COPY --from=ghcr.io/astral-sh/uv:0.13.6 /uv /uvx /bin/
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_NO_DEV=1 \
    UV_PYTHON_DOWNLOADS=0
WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-editable
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-editable --reinstall-package notes-worker

FROM python:${PYTHON_VERSION}-slim
LABEL org.opencontainers.image.title="notes-worker" \
      org.opencontainers.image.description="Fasst die Notizen aus notes-api zusammen" \
      org.opencontainers.image.source="https://example.com/docker-lab/notes"
COPY --from=build /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
WORKDIR /app
USER 65532:65532
STOPSIGNAL SIGTERM
ENTRYPOINT ["notes-worker"]
