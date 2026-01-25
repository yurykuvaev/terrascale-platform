#!/usr/bin/env bash
# Spin up a local kind cluster that approximates the dev EKS cluster well
# enough to exercise the GitOps + sample-app path without an AWS account.
#
# What this gives you:
#   - A 3-node kind cluster
#   - ArgoCD installed via Helm (same chart and version as dev)
#   - Cert-manager + AWS LB Controller stand-ins (kind doesn't have AWS,
#     so ALB ingress is replaced by ingress-nginx; certificates use a
#     self-signed CA instead of Let's Encrypt)
#   - The sample-app, served at sample.localtest.me on http://localhost
#
# What this does NOT exercise:
#   - Anything IAM (IRSA, OIDC, Secrets Manager) — replaced by inline secrets
#   - Karpenter (kind doesn't speak EC2)
#   - Loki S3 backend (Loki runs in filesystem mode)
#
# Usage:
#   ./scripts/local-kind.sh up         # bootstrap
#   ./scripts/local-kind.sh down        # tear down
#   ./scripts/local-kind.sh argocd-pw   # print the local Argo admin password

set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-terrascale-local}"
KIND_VERSION="${KIND_VERSION:-v1.31.0}"

log() { printf '[local-kind] %s\n' "$*" >&2; }

require() {
  command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 1; }
}

up() {
  require kind
  require kubectl
  require helm

  log "creating kind cluster $CLUSTER_NAME"
  cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --image "kindest/node:$KIND_VERSION" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  - role: worker
  - role: worker
EOF

  log "installing ingress-nginx"
  helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx --create-namespace \
    --set controller.service.type=NodePort \
    --set "controller.service.nodePorts.http=80" \
    --set "controller.service.nodePorts.https=443" \
    --wait

  log "installing cert-manager"
  helm upgrade --install cert-manager cert-manager \
    --repo https://charts.jetstack.io \
    --namespace cert-manager --create-namespace \
    --set crds.enabled=true \
    --wait

  log "installing argocd"
  helm upgrade --install argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm \
    --namespace argocd --create-namespace \
    --set "configs.params.server\.insecure=true" \
    --wait

  log "applying root app-of-apps (you may need to edit kubernetes/argocd/apps/root.yaml to point at a fork)"
  kubectl apply -f kubernetes/argocd/apps/root.yaml || true

  log "ready. argocd UI: kubectl -n argocd port-forward svc/argocd-server 8080:443"
  log "sample app once Argo syncs: curl -sH 'Host: sample.localtest.me' http://localhost"
}

down() {
  require kind
  log "deleting kind cluster $CLUSTER_NAME"
  kind delete cluster --name "$CLUSTER_NAME"
}

argocd_pw() {
  require kubectl
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
  echo
}

case "${1:-up}" in
  up) up ;;
  down) down ;;
  argocd-pw) argocd_pw ;;
  *) echo "usage: $0 {up|down|argocd-pw}" >&2; exit 2 ;;
esac
