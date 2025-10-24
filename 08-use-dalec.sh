#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

DALEC_REPOSITORY="${MODE}-alt"

if ! docker image ls -f "reference=controller-alt" 2> /dev/null; then
    echo "No custom Ingress Controller with DALEC image found." >&2
    exit 1
fi

DALEC_TAG=$(docker image ls -f "reference=${DALEC_REPOSITORY}" --format "{{.Tag}}" | head -n 1)
info Found DALEC image: ${DALEC_REPOSITORY}:${DALEC_TAG}

# Push the Dalec image
ACR_DALEC_LABEL=${ACR_FQDN}/${DALEC_REPOSITORY}:${DALEC_TAG}
docker tag ${DALEC_REPOSITORY}:${DALEC_TAG} ${ACR_DALEC_LABEL}
info Tagged ${DALEC_REPOSITORY}:${DALEC_TAG} as ${ACR_DALEC_LABEL}

log Pushing ${ACR_DALEC_LABEL} to ACR
docker push ${ACR_DALEC_LABEL}

# Change to using the dalec image.
if [ "${MODE}" = "ingress-nginx" ]; then
    export RUN_AS_GROUP=1000
    export RUN_AS_USER=1000
fi

./operations/configure-${MODE}.sh ${ACR_DALEC_LABEL} ${DALEC_TAG} Always

# Verify its still working
./operations/verify.sh