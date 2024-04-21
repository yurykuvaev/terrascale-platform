# Customer-managed KMS key for envelope-encryption of Kubernetes secrets at
# rest in etcd. Without this, secrets are encrypted only with the default
# AWS-managed key, which we cannot rotate or audit independently.

resource "aws_kms_key" "secrets" {
  count = var.encrypt_secrets ? 1 : 0

  description             = "EKS secrets envelope encryption for ${var.cluster_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, { Name = "${var.cluster_name}-secrets" })
}

resource "aws_kms_alias" "secrets" {
  count = var.encrypt_secrets ? 1 : 0

  name          = "alias/eks/${var.cluster_name}/secrets"
  target_key_id = aws_kms_key.secrets[0].key_id
}
