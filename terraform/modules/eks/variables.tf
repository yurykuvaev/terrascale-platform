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

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
