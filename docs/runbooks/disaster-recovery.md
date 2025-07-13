# Runbook: disaster recovery

Scope: full or partial loss of an environment. The recovery path depends
on what's lost.

## What's reproducible from git, what isn't

Reproducible from git:

- Every Terraform-managed AWS resource (VPC, EKS, IAM, S3 buckets, KMS
  keys). `terragrunt run-all apply` recreates them.
- Every Kubernetes-side platform component (controllers, AlertManager
  routes, NodePools). ArgoCD reconciles them from `kubernetes/`.
- Tenant workloads. Same — under `kubernetes/workloads/<env>/`.

**Not** reproducible from git:

- Kubernetes Secret data (synced from AWS Secrets Manager / SSM by ESO,
  but only if the values are still in those backends).
- Persistent volumes (Prometheus TSDB, Grafana, sample-app PVs).
- Loki chunks beyond the bucket lifecycle window.

## Cluster lost, AWS account intact

This is the most common case (operator error, EKS upgrade gone bad,
deliberate cluster recreation).

1. **`terragrunt destroy`** the failed cluster (only the eks unit, leave
   network alone — recreating the VPC requires NAT teardown).
2. **`terragrunt apply`** with the same `cluster_name`. State buckets are
   shared across cluster lifecycles so this is just a fresh apply.
3. **Bootstrap ArgoCD** following [argocd-bootstrap.md](argocd-bootstrap.md).
4. **Restore Prometheus storage** is optional — tsdb is lossy by design.
   The cluster-overview dashboard will backfill new data from t=now.
5. **Loki**: chunks survive in S3, the read path comes back automatically.
   No restore needed unless the bucket itself was destroyed.

Estimated downtime: 60-90 minutes for a fresh apply, plus chart sync time.

## VPC lost

Less common, more painful — destroying a VPC takes most of the platform
out and requires CIDR coordination if you re-create with different
addressing.

1. Capture the failed VPC's CIDR layout from `env.hcl` (or git history).
2. `terragrunt destroy` and `terragrunt apply` the network unit.
3. Re-apply EKS, karpenter, and the rest in order.

Estimated downtime: 2-3 hours.

## AWS account compromised

This is the only path that touches IAM aggressively.

1. **Disable** the OIDC trust on the GitHub OIDC provider (one-line
   change to `terraform/modules/github-oidc/main.tf` setting
   `client_id_list = []`, applied out-of-band by a human with a different
   role, ahead of the regular CI pipeline).
2. **Rotate** all KMS keys by replacement. EKS secrets KMS rotation is
   automatic (we set `enable_key_rotation = true`); ESO-mounted secrets
   are at risk and must be rotated in AWS Secrets Manager first.
3. **Audit CloudTrail** for the suspect window. Use Athena over the
   CloudTrail S3 export if the volume is high.
4. After containment, follow the steps in "Cluster lost" above against a
   clean account.

Coordinate with security; do not run this solo. Contact: rotate the email
in the README's `MAINTAINERS` once we have one.

## Backups we should add (TODO)

- **Velero** — for PV-aware backups of stateful workloads.
- **kube-state snapshot** — periodic dump of all CRDs to S3 for triage.
- **Grafana dashboards as code** — already covered (ConfigMaps in
  `kubernetes/platform/<env>/grafana-dashboards/`).
