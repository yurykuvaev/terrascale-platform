# cert-manager handles TLS certificate issuance. We wire the Route53 DNS-01
# solver via IRSA so DNS-validated Let's Encrypt issuers work without static
# AWS credentials. The actual ClusterIssuer manifests live in this module too
# so cert-manager is usable the moment it's installed.

variable "cert_manager_chart_version" {
  description = "cert-manager Helm chart version."
  type        = string
  default     = "v1.15.1"
}

variable "letsencrypt_email" {
  description = "Email address used for Let's Encrypt account and expiry notifications. Required for production issuer."
  type        = string
  default     = null
}

data "aws_iam_policy_document" "cert_manager" {
  statement {
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }
  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = [
      for zone_id in var.external_dns_zone_id_filters :
      "arn:aws:route53:::hostedzone/${zone_id}"
    ]
  }
  statement {
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cert_manager" {
  count = length(var.external_dns_zone_id_filters) > 0 ? 1 : 0

  name        = "${var.cluster_name}-cert-manager"
  description = "cert-manager Route53 DNS-01 solver permissions"
  policy      = data.aws_iam_policy_document.cert_manager.json
  tags        = var.tags
}

module "cert_manager_irsa" {
  count  = length(var.external_dns_zone_id_filters) > 0 ? 1 : 0
  source = "../irsa"

  role_name         = "${var.cluster_name}-cert-manager"
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url
  namespace         = "cert-manager"
  service_account   = "cert-manager"
  policy_arns       = [aws_iam_policy.cert_manager[0].arn]
  tags              = var.tags
}

resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = "baseline"
    }
  }
}

# Helm release for cert-manager has moved to ArgoCD; see
# kubernetes/platform/<env>/cert-manager.
