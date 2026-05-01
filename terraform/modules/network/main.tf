locals {
  # EKS subnet discovery tags. The AWS Load Balancer Controller and Karpenter
  # both honour these to pick subnets for ALBs and node provisioning.
  eks_public_subnet_tags = var.cluster_name == null ? {} : {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${var.cluster_name}"   = "shared"
  }

  eks_private_subnet_tags = var.cluster_name == null ? {} : {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${var.cluster_name}"   = "shared"
    "karpenter.sh/discovery"                      = var.cluster_name
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  name = var.name
  cidr = var.cidr_block

  azs             = var.azs
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs
  intra_subnets   = var.intra_subnet_cidrs

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags  = local.eks_public_subnet_tags
  private_subnet_tags = local.eks_private_subnet_tags

  tags = var.tags
}
