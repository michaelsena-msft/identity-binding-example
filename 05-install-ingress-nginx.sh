#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

# Delete the existing load balancer if it exists.
k delete --ignore-not-found=true --wait=true --now=true svc nginx -n web

# Retrieve the ingress-nginx YAML
./operations/configure.sh

# Apply ingress-nginx manifest with DNS label substitution
./operations/apply.sh


# Wait for external IP
echo "Waiting for external IP..."
for i in $(seq 1 60); do
  EXTERNAL_IP="$(k -n ingress-nginx get svc/ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || true)"
  [ -n "${EXTERNAL_IP:-}" ] && break
  sleep 5
done
[ -n "${EXTERNAL_IP:-}" ] || { echo "Timed out waiting for external IP"; exit 1; }
echo "Ingress controller IP: $EXTERNAL_IP"

# Verify DNS resolves to the IP
echo "Waiting for ${FQDN} to resolve..."
for i in $(seq 1 60); do
  RESOLVED_IPS="$(getent ahostsv4 "$FQDN" | awk '{print $1}' | sort -u || true)"
  echo "$RESOLVED_IPS" | grep -q "$EXTERNAL_IP" && break
  sleep 5
done
echo "$RESOLVED_IPS" | grep -q "$EXTERNAL_IP"

# Verify ingress controller is responding
echo "Verifying ingress controller..."
for i in $(seq 1 60); do
  STATUS="$(curl -s -o /dev/null -w "%{http_code}" "http://${FQDN}/" || true)"
  [ "$STATUS" = "404" ] && break
  sleep 5
done
[ "$STATUS" = "404" ] || { echo "Expected HTTP 404 from ingress controller"; exit 1; }
echo "Ingress controller responding with HTTP 404 (expected - no ingress rules yet)"