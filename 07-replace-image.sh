#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

if [ "${MODE}" = "ingress-nginx" ]; then
    DEFAULT_LABEL=$(grep -o '^-\W\+image:.*$' ./patches/controller-image.patch | awk '{print $3}')
    ALT_LABEL=$(echo ${DEFAULT_LABEL} | sed -e "s/registry.k8s.io/${ACR_FQDN}/g; s/@.\+//g")
elif [ "${MODE}" = "nginx-ingress" ]; then
    DEFAULT_LABEL="${DEFAULT_NGINX_INGRESS_REPOSITORY}:${DEFAULT_NGINX_INGRESS_TAG}"
    ALT_LABEL=${ACR_FQDN}/${DEFAULT_NGINX_INGRESS_REPOSITORY}:${DEFAULT_NGINX_INGRESS_TAG}
fi

log Pull and tagging image
info DEFAULT_LABEL:  ${DEFAULT_LABEL}
info ALT_LABEL:      ${ALT_LABEL}

log Pulling default image ${DEFAULT_LABEL}
docker pull ${DEFAULT_LABEL}
    
log Tagging image
docker tag ${DEFAULT_LABEL} ${ALT_LABEL}
    
log Pushing
docker push ${ALT_LABEL}

./operations/configure-${MODE}.sh ${ALT_LABEL}

./operations/verify.sh