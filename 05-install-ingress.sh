#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

./operations/configure-${MODE}.sh

# Get the controller location
if [ "${MODE}" = "ingress-nginx" ]; then
  [ "${USE_HELM}" ] && NAMESPACE=default || NAMESPACE=ingress-nginx
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