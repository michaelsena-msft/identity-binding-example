#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

export REGISTRY=${ACR_FQDN}
export IMAGE="ingress-nginx-alt"
export PULL_POLICY=Always

if ! docker image ls -f "reference=${IMAGE}" 2>&1 > /dev/null; then
    echo "No custom Ingress Controller with DALEC image found. Run: build-dalec.sh" >&2
    exit 1
fi

export TAG=$(docker image ls -f "reference=${IMAGE}" | tail -1 | awk '{print $2}')
SOURCE=${IMAGE}:${TAG}
TARGET=${ACR_FQDN}/${IMAGE}:${TAG}

log Tagging ${SOURCE} as ${TARGET}
docker tag ${SOURCE} ${TARGET}

log Pushing ${TARGET} to ACR
docker push ${TARGET}

export DIGEST=$(digest ${IMAGE}:${TAG})
info Digest: ${DIGEST}

# Change to using the dalec image.
RUN_AS_GROUP=0 RUN_AS_USER=0 RUN_AS_NONROOT=false ./operations/configure.sh

./operations/verify.sh