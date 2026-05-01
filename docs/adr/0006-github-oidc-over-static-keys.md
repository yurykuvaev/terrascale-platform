# 6. GitHub OIDC over static IAM access keys

Date: 2025-03-09

## Status

Accepted

## Decision

CI assumes AWS roles via GitHub's OIDC provider. No static `AWS_ACCESS_KEY_ID`
secrets in the repo. One role per `<env>-ci-plan` (PRs, read-only) and
`<env>-ci-apply` (push to main, read-write), trusted via subject-claim
conditions on the OIDC token.

## Why

Static keys sit in GitHub forever, get the IAM user's full permissions
every job, and don't show the workflow + branch in CloudTrail. OIDC gives
us short-lived sessions, per-job permission scoping, and an audit trail
that names the repo, branch, and run.

## Consequences

- Trust policies live in `terraform/modules/github-oidc/` and are reviewed
  in code.
- Adding a new repo to the trusted list is a Terraform change, not a
  GitHub Settings click.
- We accept that AssumeRoleWithWebIdentity sessions are 1h, which is fine
  for any sane CI run.
