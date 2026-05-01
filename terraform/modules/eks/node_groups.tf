# Managed node groups carry the system / platform workloads (ArgoCD, the
# observability stack, controllers). Application workloads land on Karpenter-
# provisioned nodes once Karpenter is online.
#
# Keeping system pods on dedicated MNG nodes keeps the platform recoverable
# even when Karpenter itself is being changed.

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
