#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

# Get details of the current image
DEFAULT_IMAGE=$(grep -o '^-\W\+image:.*$' ./patches/controller-image.patch | awk '{print $3}')
echo "Default Image: ${DEFAULT_IMAGE}"

# Pull it
echo "Pulling ${DEFAULT_IMAGE}"
docker pull ${DEFAULT_IMAGE}

# Tag it
ALT_IMAGE=$(echo ${DEFAULT_IMAGE} | sed -e "s/registry.k8s.io/${ACR_FQDN}/g; s/@.\+//g")
echo "Alt Image: ${ALT_IMAGE}"

docker tag ${DEFAULT_IMAGE} ${ALT_IMAGE}
docker push ${ALT_IMAGE}

# Make sure the file exists
./operations/configure.sh ${ALT_IMAGE}

# Apply ingress
./operations/apply.sh

# Verify its still working
./operations/verify.sh