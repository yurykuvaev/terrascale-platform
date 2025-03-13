variable "github_owner" {
  description = "GitHub user or organisation that owns the trusted repos."
  type        = string
}

variable "trusted_repos" {
  description = <<-EOT
    Map of repos that may assume the roles defined here. Each entry is a
    list of subject-claim conditions, e.g. `["repo:owner/repo:ref:refs/heads/main"]`
    or `["repo:owner/repo:pull_request"]`.
  EOT
  type        = map(list(string))
}

variable "plan_role_name" {
  description = "Name of the read-only plan role."
  type        = string
}

variable "apply_role_name" {
  description = "Name of the read-write apply role."
  type        = string
}

variable "image_publish_role_name" {
  description = "Name of the role that pushes container images."
  type        = string
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs the image-publish role may push to. Empty list = all repos in account."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to AWS resources."
  type        = map(string)
  default     = {}
}
