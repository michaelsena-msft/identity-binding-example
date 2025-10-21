#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

# Apply ingress resource with DNS label substitution
echo "Creating ingress resource..."
envsubst < 06-ingress.yaml | kubectl apply -f -

# Wait for ingress to be configured
echo "Waiting for ingress to be configured..."
sleep 5

# Show ingress status
echo "Ingress status:"
kubectl get ingress -n web

# Verify Ingress is working
./operations/verify.sh