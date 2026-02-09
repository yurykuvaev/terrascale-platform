# TerraScale Platform

[![terraform-validate](https://github.com/yurykuvaev/terrascale-platform/actions/workflows/terraform-validate.yml/badge.svg)](https://github.com/yurykuvaev/terrascale-platform/actions/workflows/terraform-validate.yml)
[![security-scan](https://github.com/yurykuvaev/terrascale-platform/actions/workflows/security-scan.yml/badge.svg)](https://github.com/yurykuvaev/terrascale-platform/actions/workflows/security-scan.yml)
[![helm-lint](https://github.com/yurykuvaev/terrascale-platform/actions/workflows/helm-lint.yml/badge.svg)](https://github.com/yurykuvaev/terrascale-platform/actions/workflows/helm-lint.yml)
[![sample-service](https://github.com/yurykuvaev/terrascale-platform/actions/workflows/sample-service.yml/badge.svg)](https://github.com/yurykuvaev/terrascale-platform/actions/workflows/sample-service.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.6-blueviolet)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.31-326ce5)](https://kubernetes.io/)

A production-grade EKS platform on AWS — Terraform and Terragrunt for the
infrastructure plane, ArgoCD for everything inside the cluster.

## What's in here

The platform delivers, end to end:

- **VPC** — 3-AZ, public + private + intra subnets, VPC endpoints (ECR /
  S3 / STS / EKS / Logs / EC2), VPC flow logs.
- **EKS** — managed node groups for system workloads, customer-managed KMS
  encryption of secrets, control-plane logging, IAM-mode auth (no
  aws-auth ConfigMap).
- **Karpenter** — application-workload autoscaling on Spot, with
  cluster-scoped IAM and EventBridge-fed interruption queue.
- **GitOps via ArgoCD** — root app-of-apps + ApplicationSets that fan out
  per environment from `kubernetes/platform/<env>/` and per tenant from
  `kubernetes/workloads/<env>/`.
- **Ingress / DNS / TLS** — AWS Load Balancer Controller, ExternalDNS,
  cert-manager with Let's Encrypt staging + prod ClusterIssuers.
- **Observability** — kube-prometheus-stack (Prometheus + Alertmanager +
  Grafana), Loki on S3, Promtail, default dashboards and PrometheusRules.
- **Secrets** — External Secrets Operator, scoped IAM per environment,
  ClusterSecretStores for AWS Secrets Manager and SSM.
- **CI/CD** — GitHub Actions with **OIDC to AWS** (no static keys),
  `terraform plan` PR comments, `terraform apply` gated on
  `environment:`, tflint / tfsec / checkov / hadolint / trivy.
- **Multi-environment** — dev, staging, prod under one Terragrunt tree with
  environment-specific overrides (single-NAT in dev, HA Argo in staging,
  private API + WAF in prod).

## Architecture

See [docs/architecture.md](docs/architecture.md) for the full picture
including a Mermaid component map and the request-time data flow.

## Layout

```
terraform/
  modules/        network · eks · karpenter · ingress · argocd ·
                  observability · secrets · irsa · github-oidc · waf
  live/           Terragrunt per-environment leaves
    _envcommon/   shared inputs per module
    dev/ staging/ prod/   per-env terragrunt.hcl
kubernetes/
  argocd/         AppProjects, ApplicationSets, root app-of-apps
  platform/      umbrella charts per environment
  workloads/     tenant Helm value overlays
charts/sample-app  first-party Helm chart for the canary workload
apps/sample-service  Go HTTP service used as the canary
docs/
  adr/           architecture decision records
  runbooks/      eks-upgrade, argocd-rollback, dr, cert-rotation
.github/workflows/  validate, plan, apply, security-scan,
                    helm-lint, sample-service, dependabot
scripts/         bootstrap-backend, update-kubeconfig, local-kind
```

## Quickstart

- **Bring up dev on AWS:** [docs/getting-started.md](docs/getting-started.md).
- **Run a kind-based local approximation** (no AWS account required):
  `./scripts/local-kind.sh up`.
- **Bootstrap ArgoCD on a fresh cluster:**
  [docs/runbooks/argocd-bootstrap.md](docs/runbooks/argocd-bootstrap.md).
- **Add a tenant workload:**
  [docs/tenant-onboarding.md](docs/tenant-onboarding.md).

## Why these choices

The contentious decisions are recorded as ADRs:

- [EKS over ECS](docs/adr/0002-choose-eks-over-ecs.md)
- [Karpenter over Cluster Autoscaler](docs/adr/0003-karpenter-over-cluster-autoscaler.md)
- [ArgoCD over Flux](docs/adr/0004-argocd-over-flux.md)
- [Terragrunt over Terraform workspaces](docs/adr/0005-terragrunt-over-workspaces.md)
- [GitHub OIDC over static IAM keys](docs/adr/0006-github-oidc-over-static-keys.md)
- [External Secrets Operator over CSI](docs/adr/0007-external-secrets-operator.md)
- [Self-host Prom/Loki over AMP/CloudWatch](docs/adr/0008-self-hosted-observability.md)

## Cost

This platform is not free to run. Steady-state estimates per environment
are in [docs/cost-analysis.md](docs/cost-analysis.md) — roughly $370/mo
for dev, $630/mo for staging, $1300+/mo for prod.

## Status

`terraform validate` clean across modules, `helm lint` clean across
charts. The platform has been built end to end as a portfolio piece;
deploying it into a real AWS account is the reader's exercise.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). For a list of recent changes,
[CHANGELOG.md](CHANGELOG.md).

## License

MIT — see [LICENSE](LICENSE).
