# notes – Demo-Anwendung für „Dockerfiles zum Anfassen"

| Dienst | Sprache | Port | Zweck |
|---|---|---|---|
| notes-api | Go | 8080 | Notizen speichern; POST verlangt `X-API-Key` |
| notes-worker | Python + uv | – | fasst die Notizen periodisch zusammen |
| notes-web | Node 24 | 3000 | Oberfläche plus Proxy auf notes-api |

Der API-Key kommt aus `NOTES_API_KEY_FILE` (bevorzugt) oder `NOTES_API_KEY`.
`.env` enthält nur Lab-Werte. `.gitignore` und `.dockerignore` fehlen absichtlich –
die entstehen an Tag 3 und Tag 12.
