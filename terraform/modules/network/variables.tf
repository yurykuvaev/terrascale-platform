variable "name" {
  description = "Name prefix applied to the VPC and all subnets."
  type        = string
}

variable "cidr_block" {
  description = "Primary CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets across. Three is recommended for production."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2 && length(var.azs) <= 4
    error_message = "Provide between 2 and 4 availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets, one per AZ."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private (workload) subnets, one per AZ."
  type        = list(string)
}

variable "intra_subnet_cidrs" {
  description = "CIDRs for intra (no-NAT) subnets used by control-plane components."
  type        = list(string)
  default     = []
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway across all AZs to save cost. Disable for prod."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name to tag subnets with for the AWS LB Controller and Karpenter discovery."
  type        = string
  default     = null
}

variable "enable_vpc_endpoints" {
  description = "Provision interface and gateway VPC endpoints for common AWS services. Disable in dev to save cost."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Capture VPC flow logs."
  type        = bool
  default     = true
}

variable "flow_logs_destination_type" {
  description = "Where to ship flow logs. Either 'cloud-watch-logs' or 's3'."
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_logs_destination_type)
    error_message = "flow_logs_destination_type must be 'cloud-watch-logs' or 's3'."
  }
}

variable "flow_logs_retention_days" {
  description = "CloudWatch retention for flow logs. Ignored when destination is S3."
  type        = number
  default     = 30
}

variable "flow_logs_kms_key_arn" {
  description = "KMS key to encrypt flow log group. Ignored when destination is S3."
  type        = string
  default     = null
}

variable "flow_logs_s3_arn" {
  description = "S3 bucket ARN that flow logs are delivered to. Required when destination is S3."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
