#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

# Note: Helm must be v3.18.4 (see: https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-helm/#before-you-begin)
# Or install...
helm upgrade --create-namespace nginx-ingress-release oci://ghcr.io/nginx/charts/nginx-ingress --version 2.3.1 \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"="${DNS_LABEL}"

 k apply -f https://raw.githubusercontent.com/nginx/kubernetes-ingress/v5.2.1/deploy/crds.yaml

# Wait for external IP
log Waiting for external IP
for i in $(seq 1 60); do
  EXTERNAL_IP="$(k -n default get svc/nginx-ingress-release-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || true)"
  [ -n "${EXTERNAL_IP:-}" ] && break
  sleep 5
done
[ -n "${EXTERNAL_IP:-}" ] || { echo "Timed out waiting for external IP"; exit 1; }
log "Ingress controller IP: $EXTERNAL_IP"

# Verify DNS resolves to the IP
echo Waiting for ${FQDN} to resolve
for i in $(seq 1 60); do
  RESOLVED_IPS="$(getent ahostsv4 "$FQDN" | awk '{print $1}' | sort -u || true)"
  echo "$RESOLVED_IPS" | grep -q "$EXTERNAL_IP" && break
  sleep 5
done
log "$RESOLVED_IPS" | grep -q "$EXTERNAL_IP"

# Verify ingress controller is responding
log Verifying ingress controller
for i in $(seq 1 60); do
  STATUS="$(curl -s -o /dev/null -w "%{http_code}" "http://${FQDN}/" || true)"
  [ "$STATUS" = "404" ] && break
  sleep 5
done
[ "$STATUS" = "404" ] || { echo "Expected HTTP 404 from ingress controller"; exit 1; }
log "Ingress controller responding with HTTP 404 (expected - no ingress rules yet)"