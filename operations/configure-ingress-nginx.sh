#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

if [ "${USE_HELM}" = "true" ]; then
    "${ROOT_DIR}"/operations/configure-ingress-nginx-helm.sh
    exit $?
fi

# Download the Azure ingress-nginx deployment (see: https://kubernetes.github.io/ingress-nginx/deploy/#azure)
log Downloading Ingress NGINX YAML
curl -o "${INGRESS_NGINX_YAML}" https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.3/deploy/static/provider/cloud/deploy.yaml

# To create a patch, uncomment this section:
#cp ingress-nginx.yaml ingress-nginx.yaml.unpatched
#info Make changes to ingress-nginx.yaml.
#info When done, enter the patch file name and hit enter "(e.g., add-customizations.patch):"
#read PATCH_FILE
#wait
#diff -U 5 ingress-nginx.yaml.unpatched ingress-nginx.yaml > ${ROOT_DIR}/patches/${PATCH_FILE}
#rm ingress-nginx.yaml.unpatched
#exit 0

log Patching Ingress NGINX YAML

# Apply the patch to have an Azure entry point.
patch -i "${ROOT_DIR}/patches/add-dns-label.patch" "${INGRESS_NGINX_YAML}" --no-backup-if-mismatch

LABEL=${1:-}
[ -z "$LABEL" ] && LABEL="${DEFAULT_INGRESS_NGINX_LABEL}"

RUN_AS_GROUP=${RUN_AS_GROUP:-}
[ -z "$RUN_AS_GROUP" ] && export RUN_AS_GROUP="${DEFAULT_INGRESS_NGINX_RUN_AS_GROUP}"
RUN_AS_USER=${RUN_AS_USER:-}
[ -z "$RUN_AS_USER" ] && export RUN_AS_USER="${DEFAULT_INGRESS_NGINX_RUN_AS_USER}"

log Patching Ingress NGINX to use image: ${LABEL} "(${RUN_AS_GROUP}:${RUN_AS_USER})"
IMAGE=${LABEL} PULL_POLICY=Always envsubst < "${ROOT_DIR}/patches/controller-image.patch" | patch "${INGRESS_NGINX_YAML}" --no-backup-if-mismatch

log Applying ingress-nginx
# Apply ingress-nginx manifest with DNS label substitution
envsubst < "${INGRESS_NGINX_YAML}" | k apply -f -

# Wait for ingress-nginx deployment to be ready
log Waiting for ingress-nginx-controller deployment
k -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=300s