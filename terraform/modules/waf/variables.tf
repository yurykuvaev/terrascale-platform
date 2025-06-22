variable "name" {
  description = "Name of the WebACL."
  type        = string
}

variable "scope" {
  description = "WAFv2 scope. Use REGIONAL for ALBs."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "rate_limit_per_5min" {
  description = "Rate-limit threshold per source IP per 5-minute window."
  type        = number
  default     = 2000
}

variable "log_destination_arn" {
  description = "Optional Kinesis Firehose / CloudWatch / S3 ARN for WAF logs. Null disables logging."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
