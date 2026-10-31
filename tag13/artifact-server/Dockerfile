# syntax=docker/dockerfile:1
# check=error=true
# artifact-server – privates Artefakt-Repository für Tag 13 (nur Lab)
# in Produktion: @sha256:… pinnen, siehe Tag 8
FROM python:3.13-slim
WORKDIR /srv
COPY server.py ./
COPY files/ ./files/
ENV PYTHONUNBUFFERED=1 PORT=8081
EXPOSE 8081
USER 65532:65532
HEALTHCHECK --interval=10s --timeout=2s --start-period=5s --start-interval=1s \
  CMD ["python3", "-c", \
       "import urllib.request as u; u.urlopen('http://127.0.0.1:8081/healthz')"]
STOPSIGNAL SIGTERM
CMD ["python3", "server.py"]
