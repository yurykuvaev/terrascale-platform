#!/usr/bin/env bash
# Bootstrap the Terraform/Terragrunt remote-state backend.
#
# Creates:
#   - S3 bucket (versioned, AES256-encrypted, public access blocked)
#   - DynamoDB table for state locking (PAY_PER_REQUEST)
#
# Idempotent: safe to re-run. Skips creation if resources already exist.
#
# Usage:
#   ./scripts/bootstrap-backend.sh <bucket-name> <table-name> [region]
#
# Example:
#   ./scripts/bootstrap-backend.sh terrascale-tfstate terrascale-tflock us-east-1

set -euo pipefail

BUCKET="${1:?bucket name required}"
TABLE="${2:?dynamodb table name required}"
REGION="${3:-us-east-1}"

log() { printf '[bootstrap] %s\n' "$*" >&2; }

# --- S3 bucket ----------------------------------------------------------------
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  log "bucket $BUCKET already exists, skipping create"
else
  log "creating bucket $BUCKET in $REGION"
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
fi

log "enforcing versioning on $BUCKET"
aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

log "enforcing AES256 encryption on $BUCKET"
aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

log "blocking public access on $BUCKET"
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# --- DynamoDB lock table ------------------------------------------------------
if aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" >/dev/null 2>&1; then
  log "table $TABLE already exists, skipping create"
else
  log "creating dynamodb table $TABLE in $REGION"
  aws dynamodb create-table \
    --region "$REGION" \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST >/dev/null
  aws dynamodb wait table-exists --table-name "$TABLE" --region "$REGION"
fi

log "done"
