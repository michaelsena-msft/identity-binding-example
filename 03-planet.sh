#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

log Applying planet
export IDENTITY_CLIENT_ID=$(az identity show -g "${RESOURCE_GROUP}" --name "${IDENTITY}" | jq -r '.clientId')
export KEYVAULT_URL=$(az keyvault show -g "${RESOURCE_GROUP}" -n "${KEY_VAULT}" | jq -r '.properties.vaultUri')
envsubst < 03-planet.yaml | k apply -f -

log Waiting for the rollout to complete
k -n web rollout status deploy/planet --timeout=120s
k -n web get pods -l app=planet -o wide
