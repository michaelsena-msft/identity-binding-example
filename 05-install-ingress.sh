#!/bin/sh
set -eou pipefail
. ./.env

# Delete the existing load balancer if it exists.
k delete --ignore-not-found=true --wait=true --now=true svc nginx -n web

# Download the Azure ingress-nginx deployment (see: https://kubernetes.github.io/ingress-nginx/deploy/#azure)
curl -o ingress-nginx.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.3/deploy/static/provider/cloud/deploy.yaml

# Apply the patch to have an Azure entry point.
patch -i 05-ingress-nginx.patch ingress-nginx.yaml

# Apply ingress-nginx manifest with DNS label substitution
envsubst < 05-ingress-nginx.yaml | k apply -f -

# Wait for ingress-nginx deployment to be ready
echo "Waiting for ingress-nginx-controller deployment..."
k -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=300s

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