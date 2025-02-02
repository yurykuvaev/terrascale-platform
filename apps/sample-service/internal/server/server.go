package server

import (
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.uber.org/zap"
)

type Config struct {
	Addr        string
	Greeting    string
	Environment string
}

func ConfigFromEnv() Config {
	cfg := Config{
		Addr:        envOr("ADDR", ":8080"),
		Greeting:    envOr("GREETING", "Hello, DevOps!"),
		Environment: envOr("ENVIRONMENT", "dev"),
	}
	return cfg
}

func envOr(key, def string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return def
}

type Server struct {
	cfg Config
	log *zap.Logger

	requests *prometheus.CounterVec
	latency  *prometheus.HistogramVec
}

func New(cfg Config, log *zap.Logger) *Server {
	return &Server{
		cfg: cfg,
		log: log,
		requests: promauto.NewCounterVec(prometheus.CounterOpts{
			Namespace: "sample_service",
			Name:      "requests_total",
			Help:      "Total HTTP requests served, by route and status.",
		}, []string{"route", "status"}),
		latency: promauto.NewHistogramVec(prometheus.HistogramOpts{
			Namespace: "sample_service",
			Name:      "request_duration_seconds",
			Help:      "Latency distribution by route.",
			Buckets:   prometheus.DefBuckets,
		}, []string{"route"}),
	}
}

func (s *Server) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.Handle("/", s.instrument("/", s.handleRoot))
	mux.Handle("/healthz", s.instrument("/healthz", s.handleHealth))
	mux.Handle("/readyz", s.instrument("/readyz", s.handleHealth))
	mux.Handle("/metrics", promhttp.Handler())
	return mux
}

func (s *Server) instrument(route string, h http.HandlerFunc) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		h(rec, r)
		dur := time.Since(start).Seconds()
		s.requests.WithLabelValues(route, strconv.Itoa(rec.status)).Inc()
		s.latency.WithLabelValues(route).Observe(dur)
		s.log.Info("served",
			zap.String("route", route),
			zap.Int("status", rec.status),
			zap.Float64("duration_seconds", dur),
			zap.String("environment", s.cfg.Environment),
		)
	})
}

func (s *Server) handleRoot(w http.ResponseWriter, _ *http.Request) {
	_, _ = w.Write([]byte(s.cfg.Greeting + "\n"))
}

func (s *Server) handleHealth(w http.ResponseWriter, _ *http.Request) {
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok\n"))
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}
