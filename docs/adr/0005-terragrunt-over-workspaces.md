# 5. Terragrunt over Terraform workspaces

Date: 2025-05-04

## Status

Accepted

## Context

We need a way to deploy the same modules across `dev`, `staging`, and `prod`
without copy-pasted `dev.tfvars`/`staging.tfvars`/`prod.tfvars`. The two
mainstream answers:

- **Terraform workspaces**, with `terraform.tfvars` files keyed by workspace.
- **Terragrunt**, the wrapper from Gruntwork that parameterises Terraform
  by HCL config.

Workspaces problems for us:

- All workspaces share one backend key, parameterised by workspace name.
  Means one tfstate per workspace per module — fine — but you can't
  configure backends differently per env (e.g. different lock tables, or
  cross-account state buckets) without per-workspace partial-config gymnastics.
- Workspaces don't help with DRY at all — `terraform.tfvars` per workspace
  is a manual file, and if you forget which workspace you're in, prod
  apply happens.
- Workspace state isolation is convention, not enforcement. CI scripts have
  to remember `workspace select` before every command.

Terragrunt wins:

- Backend is generated per leaf via the `remote_state` block in the root
  `terragrunt.hcl`. Each leaf's tfstate key is `path_relative_to_include()`
  — automatic and unambiguous.
- Provider blocks are generated per leaf, which lets us pin
  `allowed_account_ids` so applying the wrong env into the wrong account
  is a hard error.
- `_envcommon/` files express "all networks across envs are like _this_,
  except CIDRs," which is exactly what we want.
- `dependency` blocks model cross-module reads explicitly. Far less
  fragile than data sources walking name conventions.
- `run-all` orchestrates `init -> validate -> plan -> apply` across the
  whole env without us writing shell glue.

Costs we accept:

- One more binary in CI (`terragrunt` alongside `terraform`).
- The `mock_outputs` dance for `validate` is a small annoyance — required
  so dependency reads don't fail before the dependency's been applied.

## Decision

Adopt **Terragrunt** for all environments. The repository layout:

```
terraform/live/
├── terragrunt.hcl        root: backend, provider generate, default tags
├── account.hcl           AWS account id, account name
├── _envcommon/<unit>.hcl shared inputs and source pin per unit
└── <env>/
    ├── env.hcl           per-env CIDRs, region, cluster name
    └── <unit>/terragrunt.hcl   leaf with env-specific overrides
```

## Consequences

- New env = copy `dev/` → `staging/`, edit `env.hcl`, change a few overrides
  in the leaf files. No new modules.
- Cross-account state bucket and lock table are configured in the root file
  in one place; per-env config inherits.
- We commit to Gruntwork's release cadence and breaking changes (the v0.50
  → v0.60 migration in 2024 was non-trivial). Pin in CI.
