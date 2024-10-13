# ExternalDNS keeps Route53 records aligned with Service / Ingress hostnames.
#
# Permissions are scoped per hosted-zone ARN; this module accepts a list of
# zone ARNs rather than wildcarding the whole account.

variable "external_dns_chart_version" {
  description = "ExternalDNS Helm chart version."
  type        = string
  default     = "1.14.5"
}

variable "external_dns_zone_id_filters" {
  description = "Route53 hosted-zone IDs ExternalDNS may modify."
  type        = list(string)
  default     = []
}

variable "external_dns_domain_filters" {
  description = "Domain names ExternalDNS will manage. Acts as a safety net for the zone filter."
  type        = list(string)
  default     = []
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    actions = ["route53:ChangeResourceRecordSets"]
    resources = [
      for zone_id in var.external_dns_zone_id_filters :
      "arn:aws:route53:::hostedzone/${zone_id}"
    ]
  }

  statement {
    actions   = ["route53:ListHostedZones", "route53:ListResourceRecordSets", "route53:ListTagsForResource"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns" {
  count = length(var.external_dns_zone_id_filters) > 0 ? 1 : 0

  name        = "${var.cluster_name}-external-dns"
  description = "ExternalDNS Route53 access for ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.external_dns.json
  tags        = var.tags
}

module "external_dns_irsa" {
  count  = length(var.external_dns_zone_id_filters) > 0 ? 1 : 0
  source = "../irsa"

  role_name         = "${var.cluster_name}-external-dns"
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url
  namespace         = var.namespace
  service_account   = "external-dns"
  policy_arns       = [aws_iam_policy.external_dns[0].arn]
  tags              = var.tags
}

# Helm release for ExternalDNS has moved to ArgoCD; see
# kubernetes/platform/<env>/external-dns.
