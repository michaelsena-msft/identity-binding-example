#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

log Retrieving necessary information for identity binding
export NAMESPACE=demo-identity-binding
export DEPLOYMENT=ib
export IDENTITY_ID=$(az identity show -g "${RESOURCE_GROUP}" --name "${IDENTITY}" | jq -r '.id')
export IB_IDENTITY="${IDENTITY}-ib"
export ALT_IB_IDENTITY="${IDENTITY}-ib-alt"
export IDENTITY_CLIENT_ID=$(identityClientId)
export KEYVAULT_URL=$(keyvaultUrl)

if [ $# = 1 ] && [ $1 = "redeploy" ]; then
  log Deleting existing deployment
  k -n ${NAMESPACE} delete deploy/${DEPLOYMENT} --ignore-not-found=true
fi

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
  info Identity binding ${IB_IDENTITY} already exists, skipping creation.
fi

log Applying K8s YAML
envsubst < 05-ib.yaml | k apply -f -
k -n ${NAMESPACE} rollout status deploy/${DEPLOYMENT} --timeout=120s
k -n ${NAMESPACE} get pods -l app=${DEPLOYMENT} -o wide

log Allow time for the SDK example to attempt token retrieval.
sleep 45

log Verifying SDK example
if ! k logs -n ${NAMESPACE} -l app=${DEPLOYMENT} -c sdk-example | tail -1 | grep 'successfully got secret' > /dev/null; then
    echo "Authentication failing for SDK example" >&2
    exit 1
fi

log Verifying our application
if ! k logs -n ${NAMESPACE} -l app=${DEPLOYMENT} -c identity-example | tail -2 | grep 'Retrieved secret' > /dev/null; then
    echo "Authentication failing for our application" >&2
    exit 1
fi

log Checking the identity binding in the alt cluster
if ! az aks identity-binding list -g "${RESOURCE_GROUP}" --cluster-name "${ALT_CLUSTER}" --only-show-errors -o table | grep -q "${IB_IDENTITY}"; then
  info Identity binding ${IB_IDENTITY} does not exist, creating.
  az aks identity-binding create \
    -g "${RESOURCE_GROUP}" \
    --cluster-name "${ALT_CLUSTER}" \
    --name "${ALT_IB_IDENTITY}" \
    --managed-identity-resource-id "${IDENTITY_ID}" \
    --only-show-errors \
    -o table
else
  info Identity binding ${ALT_IB_IDENTITY} already exists, skipping creation.
fi

log Verifying identity bindings are the same for both clusters.
id=$(az aks identity-binding show --resource-group "${RESOURCE_GROUP}" --name "${IB_IDENTITY}" --cluster-name "${CLUSTER}" | jq -r '.properties.oidcIssuer.oidcIssuerUrl')
alt_id=$(az aks identity-binding show --resource-group "${RESOURCE_GROUP}" --name "${ALT_IB_IDENTITY}" --cluster-name "${ALT_CLUSTER}" | jq -r '.properties.oidcIssuer.oidcIssuerUrl')
if [ "$id" != "$alt_id" ]; then
    echo "OIDC Issuer URLs do not match between clusters" >&2
    exit 1
fi