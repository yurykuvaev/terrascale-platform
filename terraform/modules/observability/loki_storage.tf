# Loki chunks + TSDB index. Retention via S3 lifecycle, not Loki config.

resource "aws_s3_bucket" "loki" {
  bucket        = "${var.cluster_name}-loki"
  force_destroy = false

  tags = merge(var.tags, { Component = "loki" })
}

resource "aws_s3_bucket_versioning" "loki" {
  bucket = aws_s3_bucket.loki.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "loki" {
  bucket = aws_s3_bucket.loki.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id

  rule {
    id     = "expire-chunks"
    status = "Enabled"

    expiration {
      days = var.loki_chunk_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

data "aws_iam_policy_document" "loki" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [aws_s3_bucket.loki.arn]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.loki.arn}/*"]
  }
}

resource "aws_iam_policy" "loki" {
  name   = "${var.cluster_name}-loki"
  policy = data.aws_iam_policy_document.loki.json
  tags   = var.tags
}

module "loki_irsa" {
  source = "../irsa"

  role_name         = "${var.cluster_name}-loki"
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url
  namespace         = var.loki_namespace
  service_account   = var.loki_service_account
  policy_arns       = [aws_iam_policy.loki.arn]
  tags              = var.tags
}
