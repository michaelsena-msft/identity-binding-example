#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

./operations/configure.sh

# Get the controller location
log Waiting for external IP
for i in $(seq 1 60); do
  EXTERNAL_IP="$(k -n default get svc/ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || true)"
  [ -n "${EXTERNAL_IP:-}" ] && break
  sleep 5
done
[ -n "${EXTERNAL_IP:-}" ] || { echo "Timed out waiting for external IP" >&2; exit 1; }
info "Ingress controller IP: $EXTERNAL_IP"