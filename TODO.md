# TODO

Stuff that's not done. No promises on timing.

## Soonish

- [ ] Run the platform end-to-end in a real AWS account at least once. Right
      now everything is `terraform validate` clean but I haven't actually
      paid the EKS bill to bring it up. Until I do, the IRSA ARNs in the
      umbrella charts are placeholders that won't resolve.
- [ ] Replace the static IRSA ARN placeholders in
      `kubernetes/platform/<env>/*/values.yaml` with values pulled from a
      Terraform output via External Secrets / a config CR. Right now they're
      hand-pasted and drift the moment the role names change.
- [ ] `tflint` is finding ~10 unused variables/locals in the ingress module
      from the helm-release-to-ArgoCD migration. Real cleanup, not just
      a severity downgrade.
- [ ] Generate `apps/sample-service/go.sum` and commit it. Currently the
      Dockerfile runs `go mod tidy` to materialise it at build time. Works,
      but it costs build cache hits and lets dependency drift go unnoticed.

## Eventually

- [ ] Long-term metric retention. Prometheus' local TSDB caps at 30 days
      in prod (see `kube-prometheus-stack/values.yaml`). Thanos sidecar +
      object store, or migration to Mimir, deferred until someone actually
      needs the older data.
- [ ] Velero. Workload PVs aren't backed up. Fine for dev, scary for prod
      stateful tenants.
- [ ] Cost analysis numbers in `docs/cost-analysis.md` are estimated, not
      observed. Plug in actual numbers once a quarter has run.
- [ ] AlertManager Slack/PagerDuty webhooks reference secrets that don't
      exist yet (`alertmanager-slack`, `alertmanager-pagerduty`). Need to
      wire the ESO ExternalSecrets to populate them from Secrets Manager.
- [ ] Multi-account: today everything lives in one AWS account
      parameterised per-env. Real prod separation needs Control Tower or
      manual org+SCP work.

## Won't fix (yet)

- Production HTTPS termination assumes a real domain in Route53. The repo
  uses `example.com` placeholders. Anyone running this end-to-end has to
  bring their own zone.
- The terraform-apply workflow is `workflow_dispatch`-only because the
  repo as published has no real OIDC trust set up. Needed if you ever
  point this at an actual account.
