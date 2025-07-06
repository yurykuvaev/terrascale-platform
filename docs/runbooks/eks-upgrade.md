# Runbook: EKS minor version upgrade

How to upgrade an environment from one Kubernetes minor version to the next
(e.g. 1.30 → 1.31). Allow ~3 hours per environment, do not skip versions.

## Pre-flight

1. **Read the upstream EKS release notes** for the target version. Pay
   attention to deprecated APIs and to add-on minimum versions.
2. **Run `kubent`** against the cluster to find any in-cluster
   manifests using removed APIs:

   ```bash
   kubent --target-version 1.31
   ```

   Fix anything it flags before continuing. ArgoCD typically catches
   `apiVersion` issues at sync time, but kubent is faster.
3. **Check CRD compatibility.** Karpenter, cert-manager, External Secrets
   each pin minimum EKS versions in their release notes. Pin or bump the
   chart versions in `kubernetes/platform/<env>/<chart>/Chart.yaml` first
   (separate PR), let GitOps roll them out, then come back here.
4. **Notify tenants.** Post in #platform-announcements 48h before upgrade.

## Upgrade

1. **Bump `cluster_version`** in `terraform/live/<env>/eks/terragrunt.hcl`:

   ```hcl
   cluster_version = "1.31"
   ```

2. **Plan and apply** via PR + CI workflows. The control plane upgrade
   takes about 25 minutes and is a no-op for workloads.
3. **Bump managed node group AMI.** With
   `use_latest_ami_release_version = true` (see `node_groups.tf`) the new
   nodes pick up the upgraded AMI on next instance refresh. Trigger:

   ```bash
   aws eks update-nodegroup-version \
     --cluster-name terrascale-<env> \
     --nodegroup-name system \
     --force-update-config
   ```

   Watch the rolling replacement; system pods will reschedule onto the
   replacement nodes one at a time.
4. **Karpenter nodes.** They self-replace when their NodeClass references
   `al2023@latest` (default in our module). To force the cycle:

   ```bash
   kubectl annotate nodepool default karpenter.sh/disrupted-when=now --overwrite
   ```

   Karpenter will drift-detect and replace nodes within `expireAfter`.

## Verify

- `kubectl get nodes -o wide` — every node on the new kubelet version.
- `kubectl get componentstatuses` — all healthy.
- ArgoCD: every Application Synced/Healthy.
- Grafana: cluster-overview dashboard showing pre-upgrade and post-upgrade
  CPU/memory baselines aligned.

## Rollback

EKS does not support rolling back the control plane minor version. If the
upgrade goes badly:

- Pin everything platform-side to versions known compatible with the new
  Kubernetes version, and roll forward.
- For workloads broken by API removals, the fix is in the workload chart,
  not the cluster.

The escape hatch — provisioning a parallel cluster on the old version and
shifting traffic at DNS — is documented in
[disaster-recovery.md](disaster-recovery.md).
