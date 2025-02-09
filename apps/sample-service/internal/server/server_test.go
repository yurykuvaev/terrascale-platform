package server

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"go.uber.org/zap"
)

func newTestServer(t *testing.T, cfg Config) *Server {
	t.Helper()
	log := zap.NewNop()
	return New(cfg, log)
}

func TestRootReturnsConfiguredGreeting(t *testing.T) {
	s := newTestServer(t, Config{Greeting: "Hello, tests!"})
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rec := httptest.NewRecorder()

	s.Routes().ServeHTTP(rec, req)

	if got, want := rec.Code, http.StatusOK; got != want {
		t.Fatalf("status: got %d, want %d", got, want)
	}
	if got := strings.TrimSpace(rec.Body.String()); got != "Hello, tests!" {
		t.Fatalf("body: got %q, want %q", got, "Hello, tests!")
	}
}

func TestHealthEndpointsReturnOK(t *testing.T) {
	s := newTestServer(t, Config{})
	for _, path := range []string{"/healthz", "/readyz"} {
		t.Run(path, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, path, nil)
			rec := httptest.NewRecorder()
			s.Routes().ServeHTTP(rec, req)
			if rec.Code != http.StatusOK {
				t.Fatalf("status: got %d, want %d", rec.Code, http.StatusOK)
			}
			if !strings.Contains(rec.Body.String(), "ok") {
				t.Fatalf("body: got %q, want to contain ok", rec.Body.String())
			}
		})
	}
}

func TestMetricsEndpointExposesPrometheusFormat(t *testing.T) {
	s := newTestServer(t, Config{})

	// Hit the root once so a counter is non-zero.
	rec := httptest.NewRecorder()
	s.Routes().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

	rec = httptest.NewRecorder()
	s.Routes().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/metrics", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("status: got %d, want %d", rec.Code, http.StatusOK)
	}
	body := rec.Body.String()
	for _, want := range []string{"sample_service_requests_total", "sample_service_request_duration_seconds"} {
		if !strings.Contains(body, want) {
			t.Errorf("metrics body missing %q", want)
		}
	}
}

func TestConfigFromEnvFallsBackToDefaults(t *testing.T) {
	t.Setenv("ADDR", "")
	t.Setenv("GREETING", "")
	t.Setenv("ENVIRONMENT", "")

	cfg := ConfigFromEnv()
	if cfg.Addr != ":8080" {
		t.Errorf("Addr: got %q, want %q", cfg.Addr, ":8080")
	}
	if cfg.Greeting != "Hello, DevOps!" {
		t.Errorf("Greeting: got %q, want %q", cfg.Greeting, "Hello, DevOps!")
	}
	if cfg.Environment != "dev" {
		t.Errorf("Environment: got %q, want %q", cfg.Environment, "dev")
	}
}
