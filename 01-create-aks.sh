#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

az extension add --name aks-preview --only-show-errors || true

if ! az group list -o table | grep -q ${RESOURCE_GROUP}; then
  log Creating the resource group
  az group create \
    -n "$RESOURCE_GROUP" \
    -l "$REGION" \
    --only-show-errors \
    -o table
else
  info Resource group ${RESOURCE_GROUP} already exists, skipping creation
fi

if ! az acr list -o table | grep -q ${ACR_NAME}; then
  log Creating the ACR
  az acr create \
    --admin-enabled true \
    --sku standard \
    -g "$RESOURCE_GROUP" \
    -l "$REGION" \
    -n "$ACR_NAME" \
    --only-show-errors \
    -o table
else
  info ACR ${ACR_NAME} already exists, skipping creation
fi

if ! az keyvault list -o table | grep -q ${KEY_VAULT}; then
  log Creating the KeyVault
  az keyvault create \
    -g "$RESOURCE_GROUP" \
    --location "$REGION" \
    --name "$KEY_VAULT" \
    --sku standard \
    --only-show-errors \
    --enable-rbac-authorization \
    --enable-purge-protection \
    -o table
else
  info KeyVault ${KEY_VAULT} already exists, skipping creation
fi

if ! az identity list -o table | grep -q ${IDENTITY}; then
  log Creating an identity
  az identity create \
    --name ${IDENTITY} \
    --resource-group "${RESOURCE_GROUP}" \
    -o table
else
  info Identity ${IDENTITY} already exists, skipping creation.
fi

# Check role assignments.
IDENTITY_PRINCIPAL=$(az identity show -g ${RESOURCE_GROUP} --name ${IDENTITY} | jq -r '.principalId')
log "[ManualAction]" Ensure ${KEY_VAULT} has a role assignment 'Key Vault Secrets User' for ${IDENTITY_PRINCIPAL}

if ! az aks list -o table | grep -q ${CLUSTER}; then
  log Creating the cluster
  az aks create \
    -g "$RESOURCE_GROUP" -n "$CLUSTER" \
    --location "$REGION" \
    --node-count 1 \
    --node-vm-size Standard_D4s_v3 \
    --attach-acr $ACR_NAME \
    --only-show-errors \
    --enable-oidc-issuer \
    --enable-workload-identity \
    -o table
else
  info Cluster ${CLUSTER} already exists, skipping creation
fi

if ! az identity federated-credential list -g "${RESOURCE_GROUP}" --identity-name "${IDENTITY}" | grep -q ${FIC_IDENTITY}; then
  log Creating federated identity credential
  ISSUER_URL=$(az aks show -g "${RESOURCE_GROUP}" -n "${CLUSTER}" | jq -r '.oidcIssuerProfile.issuerUrl')
  log Issuer URL: ${ISSUER_URL}
  az identity federated-credential create \
    --name "${FIC_IDENTITY}" \
    --identity-name "${IDENTITY}" \
    --resource-group "${RESOURCE_GROUP}" \
    --issuer "${ISSUER_URL}" \
    --subject system:serviceaccount:web:astronomer-serviceaccount \
    --audience api://AzureADTokenExchange
else
  info Federated identity credential ${FIC_IDENTITY} already exists, skipping creation.
fi

# Setup environment.
./local-env.sh

# Verify cluster reachable
k get nodes -o wide
