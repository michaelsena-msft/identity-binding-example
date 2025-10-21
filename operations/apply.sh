#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

log "Applying ingress-nginx..."
# Apply ingress-nginx manifest with DNS label substitution
envsubst < "${INGRESS_NGINX_YAML}" | k apply -f -

# Wait for ingress-nginx deployment to be ready
log "Waiting for ingress-nginx-controller deployment..."
k -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=300s
