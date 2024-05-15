#!/usr/bin/env bash
# Update local kubeconfig for one of the platform environments.
#
# Reads the cluster name from terraform/live/<env>/env.hcl and resolves the
# region from the same file. Falls back to inputs on the command line.
#
# Usage:
#   ./scripts/update-kubeconfig.sh dev
#   ./scripts/update-kubeconfig.sh staging --alias terrascale-staging

set -euo pipefail

ENV="${1:?usage: update-kubeconfig.sh <env> [--alias <name>]}"
shift || true

ALIAS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --alias) ALIAS="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

ENV_HCL="terraform/live/${ENV}/env.hcl"
[[ -f "$ENV_HCL" ]] || { echo "env file not found: $ENV_HCL" >&2; exit 1; }

# Cheap and cheerful: pull the values out with sed. For anything more complex
# we should shell out to terragrunt, but that requires a working init.
extract() { sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$ENV_HCL"; }

CLUSTER_NAME="$(extract cluster_name)"
REGION="$(extract region)"

[[ -n "$CLUSTER_NAME" ]] || { echo "could not parse cluster_name from $ENV_HCL" >&2; exit 1; }
[[ -n "$REGION" ]]       || { echo "could not parse region from $ENV_HCL" >&2; exit 1; }

ALIAS_FLAG=()
[[ -n "$ALIAS" ]] && ALIAS_FLAG=(--alias "$ALIAS")

aws eks update-kubeconfig \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  "${ALIAS_FLAG[@]}"

echo "kubeconfig updated for $CLUSTER_NAME in $REGION"
