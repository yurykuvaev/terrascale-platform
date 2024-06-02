# 3. Karpenter over Cluster Autoscaler

Date: 2024-06-02

## Status

Accepted

## Context

The cluster needs node autoscaling for application workloads. Two contenders:

- **Cluster Autoscaler (CA)** — the long-standing default. Scales by adding
  or removing nodes from pre-defined ASGs. Honest, well-trusted, somewhat
  rigid.
- **Karpenter** — provisions nodes directly from EC2 based on pending pod
  requirements. No ASG plumbing in between, much wider instance-type pool,
  active consolidation.

Friction with CA in our setting:

- Each instance-type / capacity mix needs its own ASG. With Spot we want to
  diversify across many instance types — CA handles this with multiple ASGs
  but the toil scales with the matrix.
- CA can't bin-pack post-hoc. If a node is half empty after pod churn it
  stays half empty unless drained.
- Spot interruption handling requires extra glue (Node Termination Handler).

What Karpenter gives us:

- Single declarative `NodePool` describes the entire instance-type universe.
- Native consolidation: replaces over-provisioned nodes with smaller ones.
- Built-in spot interruption handling via the Spot Interruption Queue.
- Faster scale-up: pods bound to nodes in seconds, not minutes.

Friction with Karpenter:

- Newer; the v1 API is recent (2024). We accept some ongoing churn.
- IRSA + IAM permissions are non-trivial. The community has good guidance.

## Decision

Use **Karpenter** for application workloads. Keep the small managed node
group from the EKS module for system workloads (controllers, observability,
ArgoCD itself) so the cluster stays self-recoverable when Karpenter is
mid-upgrade.

## Consequences

- Application pods land on Karpenter-provisioned nodes; system pods stay on
  the MNG. We enforce this with a `system=true:NoSchedule` taint on the MNG
  and a matching toleration on system charts.
- We need a Spot Interruption Queue + IAM permissions for Karpenter to react
  to interruption notices.
- Cluster cost should drop materially over CA — both from spot density and
  consolidation. We'll measure once the platform has real load.
