// notes-api – kleines Notiz-API für das Trainingslager „Dockerfiles zum Anfassen".
//
//	GET  /healthz        → ok
//	GET  /version        → Version (per -ldflags "-X main.version=…")
//	GET  /notes          → alle Notizen als JSON
//	POST /notes          → neue Notiz {"text": "…"}, verlangt Header X-API-Key
//	GET  /upstream       → ruft NOTES_UPSTREAM per HTTPS auf (Test für CA-Zertifikate)
//
// Der API-Key kommt aus der Datei in NOTES_API_KEY_FILE oder aus NOTES_API_KEY.
// "notes-api healthcheck" prüft /healthz und eignet sich für HEALTHCHECK ohne curl.
package main

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/google/uuid"
)

var version = "dev"

type note struct {
	ID   string `json:"id"`
	Text string `json:"text"`
}

type store struct {
	mu    sync.Mutex
	notes []note
}

func loadAPIKey() (key, source string, err error) {
	if f := os.Getenv("NOTES_API_KEY_FILE"); f != "" {
		b, err := os.ReadFile(f)
		if err != nil {
			return "", "", fmt.Errorf("NOTES_API_KEY_FILE: %w", err)
		}
		return strings.TrimSpace(string(b)), "file", nil
	}
	if k := os.Getenv("NOTES_API_KEY"); k != "" {
		return k, "env", nil
	}
	return "", "", errors.New("NOTES_API_KEY oder NOTES_API_KEY_FILE fehlt")
}

func (s *store) handleNotes(apiKey string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			s.mu.Lock()
			defer s.mu.Unlock()
			writeJSON(w, http.StatusOK, s.notes)
		case http.MethodPost:
			got := r.Header.Get("X-API-Key")
			if subtle.ConstantTimeCompare([]byte(got), []byte(apiKey)) != 1 {
				writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "invalid api key"})
				return
			}
			var in struct {
				Text string `json:"text"`
			}
			if err := json.NewDecoder(r.Body).Decode(&in); err != nil || in.Text == "" {
				writeJSON(w, http.StatusBadRequest, map[string]string{"error": "text required"})
				return
			}
			n := note{ID: uuid.NewString(), Text: in.Text}
			s.mu.Lock()
			s.notes = append(s.notes, n)
			s.mu.Unlock()
			writeJSON(w, http.StatusCreated, n)
		default:
			w.WriteHeader(http.StatusMethodNotAllowed)
		}
	}
}

func handleUpstream(w http.ResponseWriter, r *http.Request) {
	url := os.Getenv("NOTES_UPSTREAM")
	if url == "" {
		url = "https://example.com"
	}
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": err.Error()})
		return
	}
	resp.Body.Close()
	writeJSON(w, http.StatusOK, map[string]any{"url": url, "status": resp.StatusCode})
}

func writeJSON(w http.ResponseWriter, code int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(v)
}

func healthcheck(addr string) int {
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://127.0.0.1" + addr + "/healthz")
	if err != nil || resp.StatusCode != http.StatusOK {
		return 1
	}
	return 0
}

func main() {
	addr := ":8080"
	if p := os.Getenv("PORT"); p != "" {
		addr = ":" + p
	}
	if len(os.Args) > 1 && os.Args[1] == "healthcheck" {
		os.Exit(healthcheck(addr))
	}

	log := slog.New(slog.NewTextHandler(os.Stdout, nil))
	apiKey, source, err := loadAPIKey()
	if err != nil {
		log.Error("start abgebrochen", "err", err)
		os.Exit(1)
	}
	// Nie den Key selbst loggen, nur woher er kam.
	log.Info("api key loaded", "source", source)

	s := &store{notes: []note{}}
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "ok")
	})
	mux.HandleFunc("/version", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, version)
	})
	mux.HandleFunc("/notes", s.handleNotes(apiKey))
	mux.HandleFunc("/upstream", handleUpstream)

	srv := &http.Server{Addr: addr, Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		log.Info("listening", "addr", addr, "version", version, "pid", os.Getpid())
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Error("server", "err", err)
			os.Exit(1)
		}
	}()

	<-ctx.Done()
	log.Info("signal received, shutting down")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Error("shutdown", "err", err)
	}
	log.Info("shutdown complete")
}
