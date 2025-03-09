# 6. GitHub OIDC over static IAM access keys

Date: 2025-03-09

## Status

Accepted

## Context

CI runs on GitHub Actions and needs to assume AWS roles to plan/apply
Terraform and to push container images to ECR / GHCR. Two ways:

1. **Static IAM access keys** stored as GitHub Action secrets.
2. **OIDC trust** between GitHub's token issuer and AWS IAM, exchanging
   short-lived JWTs for AWS session credentials at job start.

Static keys lose:

- They sit in `secrets.AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
  forever. A leaked secret stays valid until someone rotates it; nobody
  rotates it.
- The blast radius is the IAM user's full permission set, every job.
- Audit trails read like `iam-user/ci`, not `repo:owner/repo branch:main`.

OIDC wins:

- The session AssumeRoleWithWebIdentity gets exactly the permissions on the
  role we wire, scoped per-job by the trust policy's claim conditions
  (e.g. only `main` can apply, only PRs can plan).
- Sessions last 1h. There's nothing to leak from a logged variable.
- CloudTrail records the GitHub repo + workflow + branch in the user agent.

## Decision

Adopt **GitHub OIDC + AWS IAM role-per-environment**. Concretely:

- One OIDC provider per AWS account: `token.actions.githubusercontent.com`.
- One read-only `<env>-ci-plan` role with `terraform plan`-equivalent
  permissions, trusted only from PR workflows on the platform repo.
- One read-write `<env>-ci-apply` role, trusted only from `push` events on
  `main` of the platform repo.
- One `<env>-ci-image-publish` role with permission to push to ECR, trusted
  only from the `apps/**` paths on `main`.

## Consequences

- No long-lived AWS credentials live in GitHub. The compromise surface is
  the OIDC provider configuration and the trust policy claim conditions —
  both reviewed in code.
- Workflow files explicitly request the role they want with
  `aws-actions/configure-aws-credentials@v4`; we keep an allow-list of
  roles for sanity.
- Onboarding a new repo requires extending the trust policy or adding a
  new role — friction we accept.
