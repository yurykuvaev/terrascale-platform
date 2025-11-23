# Changelog

All notable changes to the platform are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the version
numbers follow [SemVer](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-11-23

First tagged release. The platform is feature-complete for what was set
out in the original design: VPC, EKS, Karpenter, GitOps via ArgoCD,
ingress + TLS, observability, secrets, multi-environment with sane
defaults per env, CI with OIDC, runbooks, ADRs.

### Added

- VPC module with 3-AZ subnets, VPC endpoints, flow logs.
- EKS module with managed node groups, KMS-encrypted secrets, control
  plane logging, and IRSA wired to the cluster's OIDC provider.
- Karpenter module with controller IRSA, Spot interruption queue,
  default NodeClass and NodePool.
- Ingress module: AWS Load Balancer Controller, ExternalDNS,
  cert-manager, Let's Encrypt staging + prod ClusterIssuers.
- ArgoCD module with HA toggle and a root app-of-apps that drives
  everything else.
- Observability stack: kube-prometheus-stack, Loki on S3 with IRSA,
  Promtail, Grafana dashboards, AlertManager routes, PrometheusRules.
- External Secrets Operator with scoped IAM and ClusterSecretStores
  for Secrets Manager and SSM.
- WAF module for prod (managed rule sets + per-IP rate limit).
- Sample Go service with multi-stage Dockerfile, distroless base,
  Helm chart, ExternalSecret integration, PodMonitor.
- Terragrunt-based dev / staging / prod environments.
- GitHub Actions: terraform-validate, terraform-plan with PR comment,
  terraform-apply with environment gating, security-scan
  (tfsec / checkov / hadolint), sample-service test/build/Trivy,
  helm-lint, Dependabot.
- Eight ADRs covering the major architectural choices.
- Runbooks: ArgoCD bootstrap, EKS upgrade, ArgoCD rollback, certificate
  rotation, disaster recovery.
- Cost analysis and tenant onboarding guide.
- Pre-commit hooks (terraform_fmt, validate, tflint, terraform_docs,
  hadolint, markdownlint).

### Notes

The repository is a portfolio piece. Modules `terraform validate` clean,
charts `helm lint` clean, but the platform has not been deployed end-to-end
into a real AWS account. AWS resource costs are documented in
[`docs/cost-analysis.md`](docs/cost-analysis.md).

[Unreleased]: https://github.com/yurykuvaev/terrascale-platform/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yurykuvaev/terrascale-platform/releases/tag/v1.0.0
