package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// Lab-Wert, kein echter Key.
const labKey = "lab-api-key-123"

func TestLoadAPIKeyFromEnv(t *testing.T) {
	t.Setenv("NOTES_API_KEY_FILE", "")
	t.Setenv("NOTES_API_KEY", labKey)
	key, source, err := loadAPIKey()
	if err != nil || key != labKey || source != "env" {
		t.Fatalf("got %q, %q, %v", key, source, err)
	}
}

func TestPostNotesRequiresKey(t *testing.T) {
	s := &store{notes: []note{}}
	h := s.handleNotes(labKey)
	cases := []struct {
		key  string
		want int
	}{
		{"", http.StatusUnauthorized},
		{"falsch", http.StatusUnauthorized},
		{labKey, http.StatusCreated},
	}
	for _, c := range cases {
		req := httptest.NewRequest(http.MethodPost, "/notes",
			strings.NewReader(`{"text":"test"}`))
		req.Header.Set("X-API-Key", c.key)
		rec := httptest.NewRecorder()
		h(rec, req)
		if rec.Code != c.want {
			t.Errorf("key %q: status %d, want %d", c.key, rec.Code, c.want)
		}
	}
}
