#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

if ! az identity federated-credential list -g "${RESOURCE_GROUP}" --identity-name "${IDENTITY}" | grep -q ${FIC_IDENTITY}; then
  log Creating federated identity credential
  ISSUER_URL=$(issuerUrl)
  log Issuer URL: ${ISSUER_URL}
  az identity federated-credential create \
    --name "${FIC_IDENTITY}" \
    --identity-name "${IDENTITY}" \
    --resource-group "${RESOURCE_GROUP}" \
    --issuer "${ISSUER_URL}" \
    --subject system:serviceaccount:${NAMESPACE}:astronomer-serviceaccount \
    --audience api://AzureADTokenExchange \
    --only-show-errors \
    -o table
else
  info Federated identity credential ${FIC_IDENTITY} already exists, skipping creation.
fi

log Applying planet
export IDENTITY_CLIENT_ID=$(az identity show -g "${RESOURCE_GROUP}" --name "${IDENTITY}" | jq -r '.clientId')
export KEYVAULT_URL=$(keyvaultUrl)
envsubst < 04-planet.yaml | k apply -f -

log Waiting for the rollout to complete
k -n ${NAMESPACE} rollout status deploy/planet --timeout=120s
k -n ${NAMESPACE} get pods -l app=planet -o wide

info Allow some time for the pods to initialize and perform OIDC authentication
sleep 30

info Verifying OIDC Container
if ! k logs -n ${NAMESPACE} -l app=planet -c oidc | tail -1 | grep 'success' > /dev/null; then
    echo "OIDC authentication failed for oidc container" >&2
    exit 1
fi

info Verifying our Application
if ! k logs -n ${NAMESPACE} -l app=planet -c identity-example | tail -2 | grep 'Retrieved secret' > /dev/null; then
    echo "OIDC authentication failed for our application" >&2
    exit 1
fi
