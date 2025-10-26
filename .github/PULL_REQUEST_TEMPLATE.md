## What

<!-- One or two sentences. What does this PR change? -->

## Why

<!-- The motivation. Bug, feature, hardening, version bump, refactor. -->

## How to verify

<!-- Concrete steps to validate the change. "Apply to dev, watch the
     ApplicationSet sync, hit the health endpoint" beats "test it". -->

## Risk

- [ ] Touches IAM
- [ ] Touches networking (VPC, SG, NACL, Route53)
- [ ] Touches cluster auth (access entries, RBAC, OIDC trust)
- [ ] Schema migration in a PV-backed component
- [ ] Helm chart major version bump
- [ ] None of the above

## Rollout

- [ ] Apply to dev only
- [ ] Apply to dev → staging → prod (with soak time between)
- [ ] Configuration only, GitOps reconciles
