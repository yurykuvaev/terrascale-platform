# 8. Self-host Prometheus and Loki over AMP / CloudWatch

Date: 2024-11-03

## Status

Accepted

## Context

We need metrics, logs, and alerting. The plausible options are:

1. **Self-hosted kube-prometheus-stack + Loki + Promtail.** Full control,
   commodity Helm chart, broad community of dashboards.
2. **Amazon Managed Prometheus (AMP) + Managed Grafana + CloudWatch logs.**
   Less to operate; AMP storage charges by sample, Managed Grafana by user.
3. **A SaaS — Datadog, Grafana Cloud, New Relic, etc.** Easiest, most
   expensive at scale, hardest to leave.

What pushes us toward self-hosting:

- **Cost shape.** AMP charges per sample ingested and per query GB-second.
  At cluster scale (~30k active series per node × 5+ nodes) the bill grows
  alarmingly. Self-hosted Prom on EBS is roughly the cost of the EBS volumes,
  full stop.
- **Loki's architecture maps cleanly to S3.** Chunks in S3, index in
  BoltDB or DynamoDB. The S3 cost dominates and is predictable.
- **Alertmanager and AMP.** AMP has Alertmanager but it's an extra service
  with its own quirks; the all-in-one chart is simpler.
- **Dashboards.** Hundreds of community dashboards target Prometheus +
  Grafana directly. Importing them works without translation.

What we'd give up:

- **Operational toil.** We own the Prometheus pod's storage, retention, and
  uptime. Mitigated by running 2 replicas with `replicaExternalLabel` and
  letting Thanos sidecar upload to S3 for long-term storage (TODO).
- **AWS-native integration.** CloudWatch metrics are still useful for AWS
  resources we don't expose to Prometheus. We'll keep CloudWatch for the
  AWS plane (ALB, EKS control plane, RDS), Prometheus for the cluster.

## Decision

Adopt:

- `kube-prometheus-stack` for Prometheus + Alertmanager + Grafana, on the
  system node group, deployed via ArgoCD.
- `loki` (single-binary mode in dev, simple-scalable in staging/prod) with
  S3 backend.
- `promtail` (DaemonSet) for log shipping — Loki's Alloy/agent rewrite is
  on the radar but the migration story is still settling.
- AlertManager routes Slack notifications by tenant label, with PagerDuty
  for prod-tier alerts.

## Consequences

- Cluster runs ~6 GiB additional memory for the observability stack, on a
  pair of `t3.large` system nodes.
- Loki S3 bucket per environment, IRSA-scoped writer role.
- Long-term metric retention beyond Prom's local TSDB needs Thanos or
  Mimir; deferred to a follow-up ADR.
