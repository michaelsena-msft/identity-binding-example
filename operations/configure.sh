#!/bin/sh
set -eou pipefail

# Download the Azure ingress-nginx deployment (see: https://kubernetes.github.io/ingress-nginx/deploy/#azure)
curl -o ingress-nginx.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.3/deploy/static/provider/cloud/deploy.yaml

# To create a patch:
#cp ingress-nginx.yaml ingress-nginx.yaml.unpatched
#<make changes>
#diff -U 5 ingress-nginx.yaml.unpatched ingress-nginx.yaml

# Apply the patch to have an Azure entry point.
patch -i "${ROOT_DIR}/patches/add-dns-label.patch" ingress-nginx.yaml --no-backup-if-mismatch

if [ "$#" -eq 1 ]; then
    IMAGE=${1} envsubst < "${ROOT_DIR}/patches/controller-image.patch" | patch ingress-nginx.yaml --no-backup-if-mismatch
fi