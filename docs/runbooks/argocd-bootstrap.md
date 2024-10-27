# Runbook: ArgoCD bootstrap

How to bring up ArgoCD on a fresh cluster and hand it the keys to the rest
of the platform.

## Prerequisites

- A running EKS cluster (apply `network` and `eks` units first).
- `kubectl` and `terragrunt` on `$PATH`.
- `AWS_PROFILE` pointed at the target account.

## Steps

1. **Update kubeconfig.**

   ```bash
   ./scripts/update-kubeconfig.sh dev
   kubectl get nodes
   ```

2. **Apply the argocd unit.**

   ```bash
   cd terraform/live/dev/argocd
   terragrunt apply
   ```

   This installs the chart, creates the namespace, and seeds the initial
   admin password (output `admin_password`, marked sensitive).

3. **Apply the root app-of-apps.**

   ```bash
   kubectl apply -f kubernetes/argocd/apps/root.yaml
   ```

   Argo now adopts every `AppProject` and `ApplicationSet` under
   `kubernetes/argocd/`. Watch the sync:

   ```bash
   kubectl -n argocd get applications -w
   ```

4. **Verify platform applications converge.**

   The platform `ApplicationSet` should produce one `Application` per
   directory under `kubernetes/platform/dev/`. Each goes Synced/Healthy
   within ~5 minutes of first apply (longer for cert-manager waiting on
   webhooks).

5. **Log in.**

   ```bash
   PASS=$(terragrunt output -raw admin_password)
   kubectl -n argocd port-forward svc/argocd-server 8080:443 &
   open https://localhost:8080
   ```

   Log in as `admin` with `$PASS`. **Rotate the admin password through the
   UI immediately**, since the bcrypt hash is in tfstate.

## Recovery

If Argo gets stuck on a CRD-before-chart ordering issue:

```bash
kubectl -n argocd patch application <name> --type merge \
  -p '{"operation": {"sync": {"syncStrategy": {"hook": {"force": true}}}}}'
```

If Argo itself is broken, terragrunt can re-apply without losing applications
because Argo state lives in CRDs in-cluster, not in tfstate. The chart
release is upgrade-safe.
