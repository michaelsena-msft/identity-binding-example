#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

./operations/configure-${MODE}.sh

# Get the controller location
if [ "${MODE}" = "ingress-nginx" ]; then
  NAMESPACE=ingress-nginx
  CONTROLLER=ingress-nginx-controller
elif [ "${MODE}" == "nginx-ingress" ]; then
  NAMESPACE=default
  CONTROLLER=nginx-ingress-release-controller
fi

log Waiting for external IP
for i in $(seq 1 60); do
  EXTERNAL_IP="$(k -n ${NAMESPACE} get svc/${CONTROLLER} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || true)"
  [ -n "${EXTERNAL_IP:-}" ] && break
  sleep 5
done
[ -n "${EXTERNAL_IP:-}" ] || { echo "Timed out waiting for external IP" >&2; exit 1; }
info "Ingress controller IP: $EXTERNAL_IP"

# Verify DNS resolves to the IP
log Waiting for ${FQDN} to resolve
for i in $(seq 1 60); do
  RESOLVED_IPS="$(getent ahostsv4 "$FQDN" | awk '{print $1}' | sort -u || true)"
  echo "$RESOLVED_IPS" | grep -q "$EXTERNAL_IP" && break
  sleep 5
done
info $RESOLVED_IPS

# Verify ingress controller is responding
log Verifying ingress controller
for i in $(seq 1 60); do
  STATUS="$(curl -s -o /dev/null -w "%{http_code}" "http://${FQDN}/" || true)"
  [ "$STATUS" = "404" ] || [ "$STATUS" = "200" ] && break
  sleep 5
done
if [ "$STATUS" = "404" ]; then
  info "Ingress controller returned HTTP 404 (expected if no default backend configured)"
elif [ "$STATUS" = "200" ]; then
  info "Ingress controller returned HTTP 200 (expected if default backend configured)"
else
  echo "Unexpected HTTP status from ingress controller: $STATUS"
  exit 1
fi