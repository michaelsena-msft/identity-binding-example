#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

# Note: Helm must be v3.18.4 (see: https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-helm/#before-you-begin)
log Configuring NGINX Ingress Controller

# Ensure PARAMS is a string accumulator (keeps backward compatible with POSIX /bin/sh)
PARAMS=${PARAMS:-}

# Append flags for any variables that are set (non-empty)
[ -n "${REGISTRY:-}" ] && PARAMS="${PARAMS} --set controller.image.registry=${REGISTRY}"
[ -n "${IMAGE:-}" ] && PARAMS="${PARAMS} --set controller.image.image=${IMAGE}"
[ -n "${TAG:-}" ] && PARAMS="${PARAMS} --set controller.image.tag=${TAG}"
[ -n "${PULL_POLICY:-}" ] && PARAMS="${PARAMS} --set controller.image.pullPolicy=${PULL_POLICY}"
[ -n "${DIGEST:-}" ] && PARAMS="${PARAMS} --set controller.image.digest=${DIGEST}"
[ -n "${RUN_AS_NONROOT:-}" ] && PARAMS="${PARAMS} --set controller.image.runAsNonRoot=${RUN_AS_NONROOT}"
[ -n "${RUN_AS_USER:-}" ] && PARAMS="${PARAMS} --set controller.image.runAsUser=${RUN_AS_USER}"
[ -n "${RUN_AS_GROUP:-}" ] && PARAMS="${PARAMS} --set controller.image.runAsGroup=${RUN_AS_GROUP}"

info Configuration overrides: ${PARAMS}

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --create-namespace \
  --atomic \
  --set controller.admissionWebhooks.enabled=false \
  --set controller.image.digestChroot="" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"="${DNS_LABEL}" \
  ${PARAMS} \
  --wait
