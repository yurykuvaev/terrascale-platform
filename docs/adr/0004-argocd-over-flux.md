# 4. ArgoCD over Flux

Date: 2024-09-08

## Status

Accepted

## Context

The platform needs a GitOps controller. Both ArgoCD and Flux are mature
CNCF graduates, both run on Kubernetes, and both deliver the same core
promise: the cluster should match what's in git, full stop.

What pushes them apart in our context:

- **Visualisation.** ArgoCD's UI is genuinely useful for triage when an
  app sync goes sideways. Flux's UI (Weave GitOps OSS) is competent but
  lighter, and Weave's commercial pivot put its long-term governance in
  question for a while.
- **ApplicationSets.** ArgoCD's `ApplicationSet` controller fits our
  multi-environment shape cleanly — one set fans out to dev/staging/prod
  using a generator. Flux has analogous primitives but they require more
  glue.
- **Sync waves and hooks.** ArgoCD's wave annotations let us order CRDs
  before charts that depend on them. Flux orders implicitly via dependsOn.
  Both work; ArgoCD's is closer to our mental model.
- **Multi-tenancy.** ArgoCD `AppProject` gives us per-tenant scopes for
  sources, destinations, RBAC. Flux has tenancy, but ArgoCD's model is
  more turnkey.

What pushes them toward Flux:

- **Smaller surface.** Flux is genuinely simpler — no UI to manage, fewer
  components.
- **Image automation.** Flux's image-update controllers are nicer out of
  the box than ArgoCD's image-updater (which is fine but noisier).

## Decision

Adopt **ArgoCD** as the platform's GitOps controller, installed in the
`argocd` namespace on the system node group. Drive every platform component
(ingress controllers, observability stack, secrets controllers) through
ArgoCD `ApplicationSet`s once Argo itself is bootstrapped by Terraform.

## Consequences

- Terraform's responsibility shrinks: it bootstraps cluster + ArgoCD + IAM,
  then hands off everything else to ArgoCD.
- Pre-existing platform charts installed by Terraform (ingress controllers,
  cert-manager) will be migrated to ArgoCD management. Done carefully via
  the `kubectl.kubernetes.io/last-applied-configuration` handoff dance.
- Tenant teams interact with the platform through `Application` /
  `ApplicationSet` PRs, not by editing Terraform.
