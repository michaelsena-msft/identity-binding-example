#!/bin/sh
set -eou pipefail
[ -f ./.env ] && [ -f ./.env ] && . ./.env || . ../.env || . ../.env

# Apply ingress-nginx manifest with DNS label substitution
envsubst < ingress-nginx.yaml | k apply -f -

# Wait for ingress-nginx deployment to be ready
echo "Waiting for ingress-nginx-controller deployment..."
k -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=300s
