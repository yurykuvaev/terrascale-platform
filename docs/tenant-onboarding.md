# Tenant onboarding

Step-by-step for adding a new tenant workload to the platform. Plan on
~1-2 hours of platform-team time per onboarding plus whatever the tenant
needs to write their own chart.

## What the platform provides out of the box

- A namespace with PSS `restricted` enforcement, default-deny
  NetworkPolicy, and a default LimitRange.
- An IRSA-capable service account (no static AWS keys).
- ExternalDNS records for any `Service` / `Ingress` host on the env's
  configured domain.
- TLS certificates from Let's Encrypt for any host the tenant claims via
  Ingress.
- A scoped ClusterSecretStore — secrets at `/<env>/<tenant>/*` in
  Secrets Manager are reachable via ExternalSecret.
- Prometheus scraping of any `PodMonitor` / `ServiceMonitor` the tenant
  ships.
- Loki indexing of every container log on the cluster.
- A Grafana dashboard slot — drop a ConfigMap with `grafana_dashboard=1`
  in the tenant namespace; the sidecar picks it up.

## Steps

### 1. Reserve a tenant identifier

The tenant identifier (e.g. `acme`) is used in:

- The Kubernetes namespace name.
- The IAM role naming convention (`terrascale-<env>-tenant-<id>`).
- The Slack channel routes in AlertManager (`#alerts-acme`).
- The Secrets Manager prefix (`/terrascale-<env>/acme/`).

Identifiers are lowercase, kebab-case, must match `[a-z][a-z0-9-]{1,30}`.

### 2. Add the tenant directory under `kubernetes/workloads/`

```
kubernetes/workloads/<env>/<tenant>/
└── values.yaml
```

The `workloads` ApplicationSet (see `kubernetes/argocd/apps/workloads.yaml`)
auto-discovers this directory and creates an Argo Application targeting
`charts/sample-app` with the tenant's `values.yaml` overlay. Tenants who
need a richer chart can ship their own under `kubernetes/workloads/<env>/<tenant>/chart/`
with a `Chart.yaml` and templates — update the ApplicationSet's `helm`
block accordingly (one-line per-tenant carve-out).

### 3. Wire AWS-side state if needed

- IRSA for AWS API access from pods: add a small Terragrunt unit at
  `terraform/live/<env>/tenants/<tenant>/`. Use the
  [`irsa`](../terraform/modules/irsa/) module. Output the role ARN; the
  tenant references it from their service account annotation.
- Secrets in Secrets Manager: place under
  `/terrascale-<env>/<tenant>/<key>` and add an `ExternalSecret` in the
  tenant chart referencing the `aws-secretsmanager` ClusterSecretStore.

### 4. Open access in the AppProject

Tenants land in the `workloads` AppProject. Default `sourceRepos`
includes `github.com/yurykuvaev/*`; if the tenant ships from elsewhere,
add their repo to `kubernetes/argocd/projects/workloads.yaml`.

### 5. Smoke test

After ArgoCD reports Synced/Healthy:

- `curl https://<host>/healthz` should return `ok`.
- Grafana → Explore → Loki, query `{namespace="<tenant>"}` should show
  startup logs.
- Prometheus → `up{namespace="<tenant>"}` should return `1`.
- Alertmanager: trigger a synthetic alert
  (`kubectl annotate ns <tenant> platform.terrascale.io/test-alert=now`)
  and confirm it lands in `#alerts-<tenant>`.

## Off-boarding

`git rm -r kubernetes/workloads/<env>/<tenant>/`. The Argo Application
finalizer cleans up the namespace and its resources. Terragrunt destroy
the IRSA role.
