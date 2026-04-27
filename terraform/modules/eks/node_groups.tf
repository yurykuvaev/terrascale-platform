# MNGs run system workloads. Apps land on Karpenter nodes via taints.
# Keeping the controllers off Karpenter keeps the cluster recoverable
# during Karpenter upgrades.

locals {
  default_node_group_defaults = {
    ami_type                       = "AL2023_x86_64_STANDARD"
    use_latest_ami_release_version = true

    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

    # Allow the kubelet to register without surprises.
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 50
          volume_type           = "gp3"
          encrypted             = true
          delete_on_termination = true
        }
      }
    }
  }
}
