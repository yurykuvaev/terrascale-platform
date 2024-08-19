# ingress

Cluster ingress, DNS, and TLS — three controllers wrapped into a single
module so they're versioned and applied together.

## What it installs

| Controller | Job |
|---|---|
| `aws-load-balancer-controller` | Provisions ALBs and NLBs from `Ingress` and `Service type=LoadBalancer` objects. |
| `external-dns` | Mirrors `Ingress` and `Service` hostnames into Route53. |
| `cert-manager` | Issues TLS certificates from Let's Encrypt via DNS-01. |

Plus two `ClusterIssuer`s (`letsencrypt-staging` and `letsencrypt-prod`)
preconfigured with the Route53 DNS-01 solver.

## IAM

Each controller has its own IAM role wired through the [`irsa`](../irsa/)
module — no shared credentials, no node-level permissions.

ExternalDNS and cert-manager scope `route53:ChangeResourceRecordSets` to the
specific hosted zones in `external_dns_zone_id_filters`, not `*`.

## Usage

```hcl
module "ingress" {
  source = "../../modules/ingress"

  cluster_name      = module.eks.cluster_name
  vpc_id            = module.network.vpc_id
  region            = "us-east-1"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  external_dns_zone_id_filters = ["Z0123456789ABCDEFGHIJ"]
  external_dns_domain_filters  = ["dev.example.com"]
  letsencrypt_email            = "platform@example.com"
}
```

## Issuing a certificate

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-tls
  namespace: my-app
spec:
  secretName: example-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - example.com
    - "*.example.com"
```

Always test with `letsencrypt-staging` first to avoid the production rate
limit (50 certificates per registered domain per week).
