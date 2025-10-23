#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

# Download the Azure ingress-nginx deployment (see: https://kubernetes.github.io/ingress-nginx/deploy/#azure)
log Downloading Ingress NGINX YAML
curl -o "${INGRESS_NGINX_YAML}" https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.3/deploy/static/provider/cloud/deploy.yaml

# To create a patch:
#cp ingress-nginx.yaml ingress-nginx.yaml.unpatched
#<make changes>
#diff -U 5 ingress-nginx.yaml.unpatched ingress-nginx.yaml

log Patching Ingress NGINX YAML

# Apply the patch to have an Azure entry point.
patch -i "${ROOT_DIR}/patches/add-dns-label.patch" "${INGRESS_NGINX_YAML}" --no-backup-if-mismatch

info Found: ${DEFAULT_INGRESS_NGINX_LABEL}
LABEL=${1:-}
[ -z "$LABEL" ] && LABEL="${DEFAULT_INGRESS_NGINX_LABEL}"

log Patching Ingress NGINX to use image: ${LABEL}
IMAGE=${LABEL} PULL_POLICY=Always envsubst < "${ROOT_DIR}/patches/controller-image.patch" | patch "${INGRESS_NGINX_YAML}" --no-backup-if-mismatch

log Applying ingress-nginx
# Apply ingress-nginx manifest with DNS label substitution
envsubst < "${INGRESS_NGINX_YAML}" | k apply -f -

# Wait for ingress-nginx deployment to be ready
log Waiting for ingress-nginx-controller deployment
k -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=300s