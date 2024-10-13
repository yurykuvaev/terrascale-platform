# Let's Encrypt ClusterIssuers — staging and production. Workloads should
# request certificates from "letsencrypt-staging" first to validate the path,
# then switch to "letsencrypt-prod" once happy. Staging certs are not trusted
# by browsers but don't count against the Let's Encrypt rate limits.

locals {
  letsencrypt_endpoints = {
    staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
    prod    = "https://acme-v02.api.letsencrypt.org/directory"
  }

  cluster_issuers_enabled = var.letsencrypt_email != null && length(var.external_dns_zone_id_filters) > 0
}

# ClusterIssuers moved to ArgoCD-managed manifests; see
# kubernetes/platform/<env>/cert-manager-issuers/.
