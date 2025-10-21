#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

DALEC_IMAGE="controller-alt"
DALEC_VERSION=v1.13.0

if ! docker image ls -f "reference=controller-alt" | grep "${DALEC_VERSION}" 2> /dev/null; then
    echo "No custom Ingress Controller with DALEC image found." >&2
    exit 1
fi

# Push the Dalec image
ACR_DALEC_IMAGE=${ACR_FQDN}/${DALEC_IMAGE}:${DALEC_VERSION}
log Tagging and pushing ${ACR_DALEC_IMAGE}
docker tag ${DALEC_IMAGE}:${DALEC_VERSION} ${ACR_DALEC_IMAGE}
docker push ${ACR_DALEC_IMAGE}

# Make sure the file exists
./operations/configure.sh ${ACR_DALEC_IMAGE}
./operations/apply.sh

./operations/verify.sh