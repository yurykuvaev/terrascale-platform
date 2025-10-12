# Architecture

The platform is one EKS cluster per environment, three environments
(`dev`, `staging`, `prod`), each provisioned by the same Terraform modules
parameterised through Terragrunt. Once Terraform brings up the cluster
plus ArgoCD, ArgoCD takes over and reconciles every other component from
this repository.

## Component map

```mermaid
flowchart TB
  subgraph AWS[AWS account per environment]
    direction TB

    VPC[VPC<br/>3 AZs<br/>public + private + intra]
    NAT[NAT Gateway<br/>per-AZ in staging/prod]
    R53[Route53 hosted zone]
    KMS[KMS key for EKS secrets]
    S3LOKI[(S3 — Loki chunks)]
    SQS[SQS — Karpenter interruption queue]
    SM[(Secrets Manager / SSM)]
    OIDC[GitHub OIDC provider]
    WAF[WAFv2 WebACL — prod only]

    subgraph EKS[EKS cluster]
      direction TB
      MNG[Managed node group<br/>system workloads]
      KARP[Karpenter NodePool<br/>application workloads]
    end
  end

  subgraph PLATFORM[Platform components in cluster]
    direction TB
    ARGO[ArgoCD]
    ALB[AWS Load Balancer Controller]
    EDNS[ExternalDNS]
    CM[cert-manager]
    KPS[kube-prometheus-stack<br/>Prom + Alertmanager + Grafana]
    LOKI[Loki + Promtail]
    ESO[External Secrets Operator]
  end

  subgraph WORKLOADS[Tenant workloads]
    direction TB
    SAMPLE[sample-service]
  end

  GH[GitHub<br/>terrascale-platform repo]

  GH -- OIDC --> OIDC
  OIDC -- AssumeRole --> AWS
  GH -- terraform plan/apply --> AWS

  ARGO -- pulls manifests --> GH
  ARGO -- reconciles --> PLATFORM
  ARGO -- reconciles --> WORKLOADS

  ALB -- IRSA --> AWS
  EDNS -- IRSA --> R53
  CM -- IRSA --> R53
  ESO -- IRSA --> SM
  LOKI -- IRSA --> S3LOKI
  KARP -- IRSA --> AWS
  KARP -- consumes --> SQS

  EKS -- envelope encrypt secrets --> KMS
  ALB -- creates ALBs in --> VPC
  WAF -. attaches to .-> ALB
```

## Data flow at request time

```mermaid
sequenceDiagram
  participant U as User
  participant DNS as Route53
  participant ALB as ALB
  participant W as WAFv2 (prod)
  participant POD as Workload pod
  participant SM as Secrets Manager
  participant ESO as External Secrets Operator

  Note over ESO,SM: 1. ExternalSecret reconcile (background, every refreshInterval)
  ESO->>SM: GetSecretValue (IRSA)
  SM-->>ESO: secret payload
  ESO->>POD: kubernetes Secret materialised

  Note over U,POD: 2. Request path
  U->>DNS: A sample.dev.example.com?
  DNS-->>U: ALB IP
  U->>ALB: HTTPS
  ALB->>W: evaluate
  W-->>ALB: ALLOW
  ALB->>POD: forward
  POD-->>ALB: 200 OK
  ALB-->>U: 200 OK
```

## Repository → cluster mapping

| Repo path | Owner | Reconciled by |
|---|---|---|
| `terraform/modules/*` | Platform | Terraform via Terragrunt |
| `terraform/live/<env>/*` | Platform | Terragrunt CI |
| `kubernetes/argocd/*` | Platform | ArgoCD (root app-of-apps) |
| `kubernetes/platform/<env>/*` | Platform | ArgoCD `platform` ApplicationSet |
| `kubernetes/workloads/<env>/<tenant>/*` | Tenant + platform review | ArgoCD `workloads` ApplicationSet |
| `charts/*` | Platform (with tenant input) | Helm via ArgoCD |
| `apps/*` | Service team | Built and pushed by GitHub Actions |
| `docs/*` | Platform | None — humans only |

## Why these choices

The big four decisions are recorded as ADRs in [`docs/adr/`](adr/):

- [ADR-0002: EKS over ECS](adr/0002-choose-eks-over-ecs.md)
- [ADR-0003: Karpenter over Cluster Autoscaler](adr/0003-karpenter-over-cluster-autoscaler.md)
- [ADR-0004: ArgoCD over Flux](adr/0004-argocd-over-flux.md)
- [ADR-0005: Terragrunt over workspaces](adr/0005-terragrunt-over-workspaces.md)
- [ADR-0006: GitHub OIDC over static keys](adr/0006-github-oidc-over-static-keys.md)
- [ADR-0007: External Secrets Operator over CSI](adr/0007-external-secrets-operator.md)
- [ADR-0008: Self-host Prom/Loki](adr/0008-self-hosted-observability.md)
