variable "cluster_name" {
  description = "EKS cluster name. Must be unique within the account/region."
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes minor version (e.g. \"1.30\")."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the cluster runs in."
  type        = string
}

variable "subnet_ids" {
  description = "Worker-node subnets. Typically the private subnets from the network module."
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "Subnets for the EKS control plane ENIs. Typically the intra subnets."
  type        = list(string)
  default     = []
}

variable "endpoint_public_access" {
  description = "Expose the cluster API to the public internet. Disable in prod and use a bastion / VPN."
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "access_entries" {
  description = <<-EOT
    Map of access entries to grant Kubernetes API access to IAM principals.
    Each entry's key is a stable identifier; the value contains principal_arn,
    type ("STANDARD" or "EC2_LINUX"/"FARGATE_LINUX"/"EC2_WINDOWS"), kubernetes_groups,
    and an optional policy_associations list.
  EOT
  type        = any
  default     = {}
}

variable "managed_node_groups" {
  description = <<-EOT
    Map of managed node group definitions. Keys are group names; values are
    objects with at least min_size, max_size, desired_size, instance_types.
    Additional fields (labels, taints, capacity_type) are forwarded as-is.
  EOT
  type        = any
  default     = {}
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
