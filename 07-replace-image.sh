#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

if [ "${MODE}" == "ingress-nginx" ]; then
    DEFAULT_LABEL=$(grep -o '^-\W\+image:.*$' ./patches/controller-image.patch | awk '{print $3}')
    ALT_REPOSITORY=$(echo ${DEFAULT_LABEL} | sed -e "s/registry.k8s.io/${ACR_FQDN}/g; s/@.\+//g")
    ALT_VERSION=${DEFAULT_NGINX_INGRESS_TAG}
elif [ "${MODE}" == "nginx-ingress" ]; then
    DEFAULT_LABEL="${DEFAULT_NGINX_INGRESS_REPOSITORY}:${DEFAULT_NGINX_INGRESS_TAG}"
    ALT_REPOSITORY="${ACR_FQDN}/${DEFAULT_NGINX_INGRESS_REPOSITORY}"
    ALT_VERSION="${DEFAULT_TAG}"
fi

log Pulling default image ${DEFAULT_LABEL}
docker pull ${DEFAULT_LABEL}
    
log Tagging image
docker tag ${DEFAULT_LABEL} ${ALT_REPOSITORY}:${ALT_VERSION}
    
log Pushing
docker push ${ALT_REPOSITORY}:${ALT_VERSION}

./operations/configure-${MODE}.sh ${ALT_IMAGE}

./operations/verify.sh