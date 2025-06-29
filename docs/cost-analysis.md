# Cost analysis

Rough monthly cost per environment, in `us-east-1`, on-demand pricing as
of mid-2025. Spot drops node cost by ~60-70% but doesn't move the
control-plane / data-transfer line items.

## Dev (single-AZ NAT, smaller cluster)

| Item | Quantity | Unit cost | Monthly |
|---|---|---|---|
| EKS control plane | 1 | $73 | **$73** |
| NAT Gateway hour | 1 | ~$32 | **$32** |
| NAT Gateway data | ~50 GB | $0.045 / GB | **$2** |
| t3.large (system MNG) | 2 | $61 | **$122** |
| Karpenter spot apps (avg) | 2× m6i.large equiv | spot | **~$60** |
| EBS gp3 (system) | 100 GiB | $0.08 / GB | **$8** |
| EBS gp3 (Prom + Loki) | 80 GiB | $0.08 / GB | **$6.40** |
| Loki S3 | ~10 GB | $0.023 / GB | **$0.23** |
| ALB hour + LCU | 1 + ~5 LCU | $16 + $40 | **$56** |
| CloudWatch logs (control plane) | ~20 GB | $0.50 / GB | **$10** |
| **Estimated total** | | | **~$370** |

## Staging (per-AZ NAT, HA argocd, longer Loki retention)

| Item | Notes | Monthly |
|---|---|---|
| EKS control plane | | **$73** |
| NAT Gateway hours | 3 × $32 | **$96** |
| NAT Gateway data | ~150 GB | **$7** |
| m6i.large × 3 (system MNG) | | **$208** |
| Karpenter spot apps | ~4 m6i.large equiv | **~$120** |
| EBS (system + obs) | ~200 GiB gp3 | **$16** |
| Loki S3 | ~50 GB, 90 d | **$1.20** |
| ALB | hour + ~10 LCU | **$96** |
| Route53 hosted zone | 1 | **$0.50** |
| CloudWatch logs | | **~$15** |
| **Estimated total** | | **~$632** |

## Prod (private API, larger system nodes, WAF, 1y log retention)

| Item | Notes | Monthly |
|---|---|---|
| EKS control plane | | **$73** |
| NAT Gateway hours | 3 × $32 | **$96** |
| NAT Gateway data | ~500 GB | **$23** |
| m6i.xlarge × 3 (system MNG) | | **$420** |
| Karpenter on-demand + spot | tenant-driven | **$300-1500** |
| EBS gp3 (system + obs) | ~500 GiB | **$40** |
| Loki S3 | ~500 GB, 365 d retention | **$11.50** |
| ALB | hour + ~30 LCU | **$256** |
| WAFv2 | $5 + $1 per rule + $0.60 per million requests | **~$15** |
| CloudWatch logs (90d retention) | | **~$40** |
| Route53 hosted zone | 1 | **$0.50** |
| Secrets Manager secrets | 50 × $0.40 | **$20** |
| **Estimated total** | | **~$1300-2500** (load-driven) |

## Cost reduction levers

- **Karpenter spot bias.** The application NodePool prefers spot; raising
  the spot weight further can cut another 5-10% if workloads tolerate it.
- **VPC endpoints.** Already enabled in all envs. Each reduces NAT data
  by the volume of traffic it absorbs (ECR, S3, STS, EKS).
- **Loki retention.** Single biggest knob in observability cost; 30 →
  365 days is roughly 12× the bucket size at steady state.
- **Single NAT in dev.** Already configured; do not propagate to staging
  or prod (single AZ outage takes the env down).
- **Reserved instances or Savings Plans.** Apply only to the system MNG
  baseline (always-on). Saves ~30-40% on those nodes.
