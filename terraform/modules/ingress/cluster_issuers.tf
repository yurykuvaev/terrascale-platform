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

resource "kubernetes_manifest" "cluster_issuer" {
  for_each = local.cluster_issuers_enabled ? local.letsencrypt_endpoints : {}

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-${each.key}"
    }
    spec = {
      acme = {
        email  = var.letsencrypt_email
        server = each.value
        privateKeySecretRef = {
          name = "letsencrypt-${each.key}-account"
        }
        solvers = [{
          dns01 = {
            route53 = {
              region = var.region
            }
          }
          selector = {
            dnsZones = var.external_dns_domain_filters
          }
        }]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}
