# Contributing

Thanks for taking the time to contribute. This is a personal portfolio
project; the bar for contributions is "is this sharper than what's there?"
rather than a formal process.

## Local setup

You need:

- `terraform` 1.6+
- `terragrunt` 0.66+
- `helm` 3.15+
- `kubectl` 1.30+
- `pre-commit` (optional but the hooks save round-trips)

Install hooks once:

```bash
pre-commit install
```

After that, every commit runs `terraform fmt`, `terraform validate`,
`tflint`, `hadolint`, `markdownlint`, and `terraform-docs` against
changed files.

## Running checks manually

```bash
make fmt-check
make validate
helm lint charts/sample-app
go -C apps/sample-service test ./...
```

## Branching and commits

- Feature branches off `main`. PRs back to `main`.
- Commit messages: short imperative subject, sentence case. Reference
  the affected module or area when it isn't obvious from the diff.
  Examples: "Add Karpenter NodePool drift policy", "Tighten ALB
  controller IAM scope".
- Squash on merge for tenant work; preserve history for platform changes
  worth reading.

## Adding a new platform component

1. If it has AWS resources, add a Terraform module in
   `terraform/modules/<component>/` with `versions.tf`, `variables.tf`,
   `main.tf`, `outputs.tf`, and a hand-written `README.md`.
2. If it has Kubernetes resources, add an umbrella chart per environment
   under `kubernetes/platform/<env>/<component>/`.
3. Wire it into Terragrunt under `terraform/live/_envcommon/<component>.hcl`
   and per-env `terraform/live/<env>/<component>/terragrunt.hcl`.
4. The platform `ApplicationSet` picks up the chart automatically — no
   manual Application needed.
5. Update [`docs/architecture.md`](docs/architecture.md). Add an ADR if
   the choice is contentious.

## Adding a new tenant workload

See [docs/tenant-onboarding.md](docs/tenant-onboarding.md).

## ADRs

Significant architecture decisions get an ADR in `docs/adr/`. Use the
template at the bottom of [ADR-0001](docs/adr/0001-record-architecture-decisions.md).
ADRs are numbered, immutable once accepted, and superseded rather than
edited.

## Code style

- Terraform: `terraform fmt`. Tag variables, outputs, and resources with
  descriptions. Sort variables required-first.
- Go: `gofmt`, `go vet`, race detector on tests.
- Helm: `helm lint`, conservative use of `with`/`include`. Avoid global
  values; per-chart values keep blast radius small.
- YAML: 2-space indent, no tabs, comments allowed and encouraged.

## Reviewing

- Plans (`terragrunt plan`) for the affected env are posted to PRs by CI.
  Read them.
- Changes that affect IAM, networking, or cluster security need a second
  reviewer. The CODEOWNERS file enforces this where I have it set up.
- Helm chart changes that bump major versions need a sync-on-staging step
  before main lands.

## Reporting issues

Open a GitHub issue with the env, the symptom, and as much of the relevant
log / Argo state as you have. For things that look security-relevant,
email rather than open a public issue.
