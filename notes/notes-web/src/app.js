// Wird mit esbuild nach dist/app.js gebündelt (npm run build).
const list = document.querySelector("#notes");
const form = document.querySelector("#new");

async function load() {
  const notes = await (await fetch("/api/notes")).json();
  list.replaceChildren(
    ...notes.map((n) => Object.assign(document.createElement("li"), { textContent: n.text })),
  );
}

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const text = new FormData(form).get("text");
  await fetch("/api/notes", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text }),
  });
  form.reset();
  load();
});

load();
