# 2. Choose EKS over ECS as the platform runtime

Date: 2024-04-07

## Status

Accepted

## Context

The earlier TerraScale prototype ran on ECS on EC2. ECS is a fine fit for
1-2 services, but as we evolve into a multi-tenant platform we need:

- **Workload portability.** Vendor-specific task definitions don't move; Helm
  charts and Kubernetes manifests do.
- **A larger ecosystem.** Most modern platform tooling (ArgoCD, Karpenter,
  Prometheus, cert-manager, External Secrets Operator) lives in the Kubernetes
  world first and reaches ECS late or not at all.
- **Strong multi-tenancy primitives.** Namespaces, NetworkPolicies, RBAC, and
  PSS give us tenant isolation that ECS would force us to bolt on with IAM
  and account-level boundaries.
- **GitOps as a first-class concept.** ArgoCD/Flux assume Kubernetes.

We considered:

- **ECS Fargate.** Simpler operationally; loses ecosystem and GitOps story.
- **EKS Auto Mode (when GA).** Worth re-evaluating once it's stable. Today
  it constrains node configuration in ways we'd outgrow.
- **Self-managed Kubernetes (kops, kubeadm).** Operational overhead is a
  tax we can't justify without a specific reason to leave EKS.

## Decision

Adopt **Amazon EKS** with **managed node groups** for the system workloads
(controllers, observability stack) and **Karpenter** for application workloads
once the cluster is stable.

## Consequences

- We accept the EKS control plane cost (~$73/month per cluster) in exchange
  for AWS managing etcd, upgrades, and the API server.
- We adopt the broader Kubernetes ecosystem; we also inherit its complexity.
  Mitigated by leaning on community modules and well-trodden patterns.
- Our IaC must wire IRSA, OIDC, and access entries — not zero work, but a
  one-time investment.
