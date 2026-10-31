// notes-web – liefert public/ und dist/ aus und leitet /api/* an notes-api weiter.
import express from "express";

const app = express();
const api = process.env.NOTES_API_URL ?? "http://notes-api:8080";
const port = Number(process.env.PORT ?? 3000);

app.use(express.json());
app.use(express.static("public"));
app.use("/assets", express.static("dist"));

app.get("/healthz", (_req, res) => res.send("ok"));

// Der Browser kennt den API-Key nicht; notes-web hängt ihn serverseitig an.
app.all("/api/notes", async (req, res) => {
  const headers = { "Content-Type": "application/json" };
  if (req.method === "POST") headers["X-API-Key"] = process.env.NOTES_API_KEY ?? "";
  const upstream = await fetch(`${api}/notes`, {
    method: req.method,
    headers,
    body: req.method === "POST" ? JSON.stringify(req.body) : undefined,
  });
  res.status(upstream.status).type("json").send(await upstream.text());
});

const server = app.listen(port, () => console.log(`notes-web listening on :${port}`));
for (const sig of ["SIGTERM", "SIGINT"]) {
  process.on(sig, () => {
    console.log(`${sig} received, shutting down`);
    server.close(() => process.exit(0));
  });
}
