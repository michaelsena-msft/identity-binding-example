#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

if [ "${MODE}" = "ingress-nginx" ]; then
    REGISTRY=${DEFAULT_INGRESS_NGINX_REGISTRY}
    IMAGE=${DEFAULT_INGRESS_NGINX_IMAGE}
    TAG=${DEFAULT_INGRESS_NGINX_TAG}
    DIGEST=${DEFAULT_INGRESS_NGINX_DIGEST}
elif [ "${MODE}" = "nginx-ingress" ]; then
    REGISTRY=${DEFAULT_NGINX_INGRESS_REGISTRY}
    IMAGE=${DEFAULT_NGINX_INGRESS_IMAGE}
    TAG=${DEFAULT_NGINX_INGRESS_TAG}
    DIGEST=${DEFAULT_NGINX_INGRESS_DIGEST}
fi

SOURCE=${REGISTRY}/${IMAGE}:${TAG}@${DIGEST}
TARGET=${ACR_FQDN}/${IMAGE}:${TAG}

log Pulling default image ${SOURCE}
docker pull ${SOURCE}

log Tagging ${SOURCE} as ${TARGET}
docker tag ${SOURCE} ${TARGET}
    
log Pushing ${TARGET} to ACR
docker push ${TARGET}

export DIGEST=$(digest ${IMAGE}:${TAG})
info Digest: ${DIGEST}
REGISTRY=${ACR_FQDN} PULL_POLICY=Always ./operations/configure-${MODE}.sh

./operations/verify.sh