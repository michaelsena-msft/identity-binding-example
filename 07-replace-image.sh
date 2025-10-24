#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

SOURCE=${DEFAULT_INGRESS_NGINX_REGISTRY}/${DEFAULT_INGRESS_NGINX_IMAGE}:${DEFAULT_INGRESS_NGINX_TAG}@${DEFAULT_INGRESS_NGINX_DIGEST}
TARGET=${ACR_FQDN}/${DEFAULT_INGRESS_NGINX_IMAGE}:${DEFAULT_INGRESS_NGINX_TAG}

log Pulling default image ${SOURCE}
docker pull ${SOURCE}

log Tagging ${SOURCE} as ${TARGET}
docker tag ${SOURCE} ${TARGET}
    
log Pushing ${TARGET} to ACR
docker push ${TARGET}

export DIGEST=$(digest ${DEFAULT_INGRESS_NGINX_IMAGE}:${DEFAULT_INGRESS_NGINX_TAG})
info Digest: ${DIGEST}
REGISTRY=${ACR_FQDN} PULL_POLICY=Always ./operations/configure.sh

./operations/verify.sh