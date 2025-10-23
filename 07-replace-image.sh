#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

if [ "${MODE}" = "ingress-nginx" ]; then
    DEFAULT_LABEL=${DEFAULT_INGRESS_NGINX_LABEL}
    ALT_LABEL=$(echo ${DEFAULT_LABEL} | sed -e "s/registry.k8s.io/${ACR_FQDN}/g; s/@.\+//g")
elif [ "${MODE}" = "nginx-ingress" ]; then
    DEFAULT_LABEL="${DEFAULT_NGINX_INGRESS_REPOSITORY}:${DEFAULT_NGINX_INGRESS_TAG}"
    ALT_LABEL=${ACR_FQDN}/${DEFAULT_NGINX_INGRESS_REPOSITORY}:${DEFAULT_NGINX_INGRESS_TAG}
fi

log Pulling default image ${DEFAULT_LABEL}
docker pull ${DEFAULT_LABEL}
    
log Tagging ${DEFAULT_LABEL} as ${ALT_LABEL}
docker tag ${DEFAULT_LABEL} ${ALT_LABEL}
    
log Pushing ${ALT_LABEL} to ACR
docker push ${ALT_LABEL}

./operations/configure-${MODE}.sh ${ALT_LABEL}

./operations/verify.sh