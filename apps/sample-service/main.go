// sample-service is the canary workload for the platform. It exposes a tiny
// HTTP API plus Prometheus metrics, logs structured JSON to stdout, and
// reads a greeting message from a Kubernetes Secret mounted via envFrom.
//
// Its job is to give us a small, real workload to exercise the full stack:
// ALB ingress, cert-manager TLS, ExternalDNS records, ESO secret rendering,
// Prometheus scraping, Loki log shipping.
package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/yurykuvaev/terrascale-platform/apps/sample-service/internal/server"

	"go.uber.org/zap"
)

func main() {
	cfg := server.ConfigFromEnv()

	log, err := zap.NewProduction()
	if err != nil {
		panic(err)
	}
	defer func() { _ = log.Sync() }()

	srv := server.New(cfg, log)

	httpServer := &http.Server{
		Addr:              cfg.Addr,
		Handler:           srv.Routes(),
		ReadHeaderTimeout: 5 * time.Second,
	}

	idleClosed := make(chan struct{})
	go func() {
		sig := make(chan os.Signal, 1)
		signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
		<-sig

		log.Info("shutdown initiated")
		ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
		defer cancel()
		if err := httpServer.Shutdown(ctx); err != nil {
			log.Error("graceful shutdown failed", zap.Error(err))
		}
		close(idleClosed)
	}()

	log.Info("server starting", zap.String("addr", cfg.Addr), zap.String("greeting", cfg.Greeting))
	if err := httpServer.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal("listen and serve failed", zap.Error(err))
	}

	<-idleClosed
	log.Info("server stopped cleanly")
}
