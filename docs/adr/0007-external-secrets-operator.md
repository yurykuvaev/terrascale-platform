# 7. External Secrets Operator over Secrets Manager CSI driver

Date: 2025-01-12

## Status

Accepted

## Context

We need a way to surface secrets from AWS Secrets Manager (and Parameter
Store) into pods. The two main options are:

1. **Secrets Manager and Parameter Store CSI driver** — mounts secrets as
   files via a CSI volume. Per-pod, no Kubernetes Secret object.
2. **External Secrets Operator (ESO)** — reconciles `ExternalSecret`
   resources into native Kubernetes `Secret` objects.

Why ESO:

- **Native Secret objects.** Workloads consume `Secret`s the same way they
  always have — `envFrom`, `secretRef`, image-pull secrets, etc. Helm
  charts that don't speak CSI work unchanged.
- **Caching and rate-limiting.** ESO batches reconciles across many
  ExternalSecret objects against the same backend, which keeps us comfortably
  below Secrets Manager's TPS quotas. The CSI driver pulls per-pod-mount.
- **Multiple backends.** ESO speaks SSM, Secrets Manager, Vault, GCP/Azure
  equivalents, and several others. We start with AWS but the door stays
  open.
- **`PushSecret`.** ESO can push generated values back to Secrets Manager.
  Useful for the chicken-and-egg of bootstrapping a database password.

What we give up:

- **In-pod-only secrets.** CSI's "secret never lands in etcd" property is
  a real win for the truly sensitive values. ESO writes to etcd (encrypted
  at rest by our KMS key — see ADR-0002 / EKS module). For any value where
  this is unacceptable we'll mount it via CSI alongside ESO.

## Decision

Adopt **External Secrets Operator** as the primary mechanism for surfacing
Secrets Manager / SSM values into the cluster. Deploy via ArgoCD, configure
a `ClusterSecretStore` per backend (Secrets Manager, SSM Parameter Store)
backed by IRSA.

Reach for the CSI driver only for values that must not land in etcd.

## Consequences

- One IRSA role per environment with read-only access to a scoped prefix
  in Secrets Manager and SSM.
- Tenants create namespaced `ExternalSecret` objects referencing the cluster
  store, never AWS API tokens directly.
- Secret rotation in AWS triggers ESO to re-sync within `refreshInterval`
  (default 1h, tunable per resource).
