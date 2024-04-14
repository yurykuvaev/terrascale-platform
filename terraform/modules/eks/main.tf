module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.13"

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

  eks_managed_node_group_defaults = local.default_node_group_defaults
  eks_managed_node_groups         = var.managed_node_groups

  tags = var.tags
}
