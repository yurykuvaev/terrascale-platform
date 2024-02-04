# TerraScale Platform

A production-grade EKS platform on AWS, built with Terraform and Terragrunt.

This repository provisions the foundation for a multi-tenant Kubernetes platform:
networking, EKS clusters, autoscaling, GitOps delivery, observability, ingress,
and secrets management — across `dev`, `staging`, and `prod` environments.

> Status: early scaffolding. See `docs/` for architecture and roadmap.

## Layout

```
terraform/modules/   reusable Terraform modules
terraform/live/      Terragrunt configuration per environment
kubernetes/          ArgoCD applications and Helm value overrides
charts/              first-party Helm charts
apps/                first-party container workloads
docs/                architecture, ADRs, runbooks
```

## Quickstart

Coming soon.

## License

MIT — see [LICENSE](LICENSE).
