#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

log Retrieving necessary information for identity binding
export NAMESPACE=demo-identity-binding
export DEPLOYMENT=ib
export IDENTITY_ID=$(az identity show -g "${RESOURCE_GROUP}" --name "${IDENTITY}" | jq -r '.id')
export IB_IDENTITY="${IDENTITY}-ib"
export IDENTITY_CLIENT_ID=$(identityClientId)
export KEYVAULT_URL=$(keyvaultUrl)

log Checking the identity binding
if ! az aks identity-binding list -g "${RESOURCE_GROUP}" --cluster-name "${CLUSTER}" --only-show-errors -o table | grep -q "${IB_IDENTITY}"; then
  info Identity binding ${IB_IDENTITY} does not exist, creating.
  az aks identity-binding create \
    -g "${RESOURCE_GROUP}" \
    --cluster-name "${CLUSTER}" \
    --name "${IB_IDENTITY}" \
    --managed-identity-resource-id "${IDENTITY_ID}" \
    --only-show-errors \
    -o table
else
  info Identity binding for ${IDENTITY} already exists, skipping creation.
fi

log Applying K8s YAML
envsubst < 05-ib.yaml | k apply -f -
k -n ${NAMESPACE} rollout status deploy/${DEPLOYMENT} --timeout=120s
k -n ${NAMESPACE} get pods -l app=${DEPLOYMENT} -o wide

log Allow some time for the pods to initialize and perform OIDC authentication
sleep 30

info Verifying OIDC Container
if ! k logs -n ${NAMESPACE} -l app=${DEPLOYMENT} -c oidc | tail -1 | grep 'successfully got secret' > /dev/null; then
    echo "OIDC authentication failed for oidc container" >&2
    exit 1
fi
