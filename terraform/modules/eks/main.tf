module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.19"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = length(var.control_plane_subnet_ids) > 0 ? var.control_plane_subnet_ids : var.subnet_ids

  cluster_endpoint_public_access       = var.endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  cluster_endpoint_private_access      = true

  # Authentication mode: API only (no aws-auth ConfigMap).
  authentication_mode = "API"

  enable_cluster_creator_admin_permissions = true

  cluster_enabled_log_types              = var.control_plane_log_types
  cloudwatch_log_group_retention_in_days = var.control_plane_log_retention_days

  cluster_encryption_config = var.encrypt_secrets ? {
    resources        = ["secrets"]
    provider_key_arn = aws_kms_key.secrets[0].arn
  } : {}

  # The upstream module also creates a KMS key when one isn't provided. Disable
  # that path because we manage the key explicitly (so rotation and alias are
  # under our control).
  create_kms_key = false

  # Tighter node-to-node rules. The module's defaults are pretty permissive;
  # we narrow ingress to only what kubelet, CoreDNS, and the AWS LB Controller
  # need. NodePort ranges stay open inside the SG itself.
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    ingress_cluster_kubelet = {
      description                   = "Cluster API to node kubelets"
      protocol                      = "tcp"
      from_port                     = 10250
      to_port                       = 10250
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_alb_webhooks = {
      description                   = "Cluster API to AWS LB Controller webhook"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  eks_managed_node_group_defaults = local.default_node_group_defaults
  eks_managed_node_groups         = var.managed_node_groups

  access_entries = var.access_entries

  tags = var.tags
}
