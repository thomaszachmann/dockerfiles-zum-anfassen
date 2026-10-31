# syntax=docker/dockerfile:1
# probe – zeigt, wie ein Build-Secret im RUN ankommt und wieder verschwindet (Tag 13)
# in Produktion: @sha256:… pinnen, siehe Tag 8
FROM golang:1.27-alpine
# 1) Standard: Datei unter /run/secrets/<id>, root, 0400
RUN --mount=type=secret,id=artifact_token \
    ls -ln /run/secrets
# 2) eigener Pfad, eigene Rechte
RUN --mount=type=secret,id=artifact_token,target=/tmp/token,mode=0440,uid=65532 \
    ls -ln /tmp/token
# 3) nur als Umgebungsvariable (dann ohne Datei)
RUN --mount=type=secret,id=artifact_token,env=ARTIFACT_TOKEN \
    echo "ARTIFACT_TOKEN hat ${#ARTIFACT_TOKEN} Zeichen" \
    && test ! -e /run/secrets/artifact_token && echo "keine Datei unter /run/secrets"
# 4) ohne Mount: nichts mehr da
RUN test ! -s /run/secrets/artifact_token && test ! -s /tmp/token \
    && echo "ohne Mount: kein Secret-Inhalt im Dateisystem"
