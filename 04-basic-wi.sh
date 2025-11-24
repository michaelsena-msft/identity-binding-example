#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

export NAMESPACE=demo-workload-identity
export DEPLOYMENT=wi
FIC_IDENTITY=${RESOURCE_GROUP}-fic

if [ $# = 1 ] && [ $1 = "redeploy" ]; then
  log Deleting existing deployment
  k -n ${NAMESPACE} delete deploy/${DEPLOYMENT} --ignore-not-found=true
fi

if az identity federated-credential list -g "${RESOURCE_GROUP}" --identity-name "${IDENTITY}" | grep -q ${FIC_IDENTITY}; then
  verb=update
else
  verb=create
fi

log Handling federated identity credential, op=${verb}
ISSUER_URL=$(az aks show -g "${RESOURCE_GROUP}" -n "${CLUSTER}" | jq -r '.oidcIssuerProfile.issuerUrl')
info Issuer URL: ${ISSUER_URL}
az identity federated-credential ${verb} \
  --name "${FIC_IDENTITY}" \
  --identity-name "${IDENTITY}" \
  --resource-group "${RESOURCE_GROUP}" \
  --issuer "${ISSUER_URL}" \
  --subject system:serviceaccount:${NAMESPACE}:${DEPLOYMENT}-serviceaccount \
  --audience api://AzureADTokenExchange \
  --only-show-errors \
  -o table

log Applying K8s YAML
export IDENTITY_CLIENT_ID=$(identityClientId)
export KEYVAULT_URL=$(keyvaultUrl)
envsubst < 04-basic-wi.yaml | k apply -f -
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
