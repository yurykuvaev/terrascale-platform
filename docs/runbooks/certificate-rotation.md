# Runbook: certificate rotation

Day-to-day: cert-manager renews Let's Encrypt certs automatically 30 days
before expiry. This runbook is for the unhappy paths.

## Verify a certificate is healthy

```bash
kubectl get certificate -A
kubectl describe certificate -n <ns> <name>
```

A healthy cert shows `Ready=True` and `Renewal Time` ~30 days before the
`Not After` of the issued chain.

## Force renewal

If the renewal didn't fire (clock skew, broken solver, expired Let's
Encrypt account), trigger one manually:

```bash
kubectl cert-manager renew -n <ns> <cert-name>
```

(Requires the `cmctl` plugin. Without it, delete the secret and let the
controller re-issue.)

## Rotating Let's Encrypt account keys

Account keys live in `letsencrypt-prod-account` / `letsencrypt-staging-account`
in the `cert-manager` namespace. To rotate:

1. Bump the `metadata.annotations["acme.cert-manager.io/account-rotation"]`
   stamp on the ClusterIssuer manifests under
   `kubernetes/platform/<env>/cert-manager-issuers/`.
2. Commit, PR, merge. ArgoCD applies the change and cert-manager
   re-registers with Let's Encrypt under a new key.
3. Existing certificates aren't invalidated. New issuances use the new
   key.

## Hitting Let's Encrypt rate limits

- 50 new certificates per registered domain per week.
- 5 duplicate certificates per registered domain per week.
- 300 new orders per account per 3 hours.

If we hit a limit, switch the affected workloads to the `letsencrypt-staging`
issuer until the window expires. Staging certs aren't browser-trusted but
they don't count against the prod limit.

## DNS-01 solver broken

cert-manager logs will show `dns-01: failed to get hosted zone`. Causes:

- IRSA role missing `route53:ListHostedZonesByName`. Check
  `terraform/modules/ingress/cert_manager.tf` against the current policy.
- The hosted zone ID in `terraform/live/<env>/ingress/terragrunt.hcl`
  doesn't match the actual zone (someone re-created the zone).
- The cluster's IRSA token expired — `kubectl rollout restart -n cert-manager
  deploy/cert-manager` forces a re-mint.

## Switching CA

If we need to migrate off Let's Encrypt (rate limits, account suspended,
policy change), the path is:

1. Add a new `ClusterIssuer` referencing the new CA (e.g. ACM Private CA,
   ZeroSSL).
2. Update each `Certificate.spec.issuerRef.name` in the affected charts.
3. Sync. cert-manager re-issues without downtime — old certs remain valid
   in their `Secret`s until replaced on next renewal.
