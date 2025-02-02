# sample-service

A tiny Go HTTP service used as the canary workload for the platform. It
exposes:

| Path | Purpose |
|---|---|
| `/` | Returns the configured greeting (default `Hello, DevOps!`). |
| `/healthz`, `/readyz` | Liveness / readiness probes. |
| `/metrics` | Prometheus metrics. |

Configuration via environment variables:

| Env | Default | Notes |
|---|---|---|
| `ADDR` | `:8080` | Listen address. |
| `GREETING` | `Hello, DevOps!` | Greeting body for `/`. Sourced from a Kubernetes Secret in deployments. |
| `ENVIRONMENT` | `dev` | Log label only. |

## Build

```bash
go build ./...
```

## Run

```bash
GREETING="Hello from local" go run .
curl -s localhost:8080
```
