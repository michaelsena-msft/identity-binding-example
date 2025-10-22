#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

# Apply ingress resource with DNS label substitution
log Creating ingress resource
envsubst < 06-ingress.yaml | kubectl apply -f -

# Wait for ingress to be configured
log Waiting for ingress to be configured
sleep 5

log Checking ${FQDN}

# Show ingress status
log Ingress status:
kubectl get ingress -n web

# Verify ingress routes
./operations/verify.sh