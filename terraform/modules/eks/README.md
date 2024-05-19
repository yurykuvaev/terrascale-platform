# eks

Wraps `terraform-aws-modules/eks/aws` with the platform's defaults:

- API-only authentication mode (no aws-auth ConfigMap drift)
- Customer-managed KMS key for envelope encryption of secrets
- Control plane logging enabled by default (api/audit/authenticator/cm/sched)
- Managed node group defaults: AL2023, gp3 50 GiB encrypted root, SSM
- Pinned EKS module version, pinned AWS provider

System workloads (controllers, observability, GitOps) land on the managed
node groups defined here. Application workloads should land on Karpenter
nodes — provisioned by the [`karpenter`](../karpenter/) module.

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "terrascale-dev"
  cluster_version = "1.30"

  vpc_id                   = module.network.vpc_id
  subnet_ids               = module.network.private_subnet_ids
  control_plane_subnet_ids = module.network.intra_subnet_ids

  managed_node_groups = {
    system = {
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }

  access_entries = {
    platform_admin = {
      principal_arn = "arn:aws:iam::123456789012:role/PlatformAdmin"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }
}
```

## Notes

- `endpoint_public_access` defaults to `true` for development convenience.
  In staging/prod, disable it and reach the API via VPN, bastion, or
  AWS Client VPN.
- `create_kms_key` is forced to `false` because we manage the KMS key
  ourselves so we can attach our own alias and rotate independently.
- Setting `encrypt_secrets = false` is supported but **not recommended**.
