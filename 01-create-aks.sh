#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

if false; then
  if ! az extension show --name aks-preview -o table --only-show-errors > /dev/null; then
    info Installing the aks-preview extension
    az extension add --name aks-preview --only-show-errors
  else
    info Ensuring latest aks-preview extension is installed
    az extension update --name aks-preview --only-show-errors
  fi
fi

isRegistered() {
  state=$(az feature show --namespace Microsoft.ContainerService --name IdentityBindingPreview | jq -r '.properties.state')
  [ "$state" = "Registered" ] && return 0 || return 1
}

if ! isRegistered; then
  info Registering the IdentityBindingPreview feature
  az feature register --namespace Microsoft.ContainerService --name IdentityBindingPreview --only-show-errors -o table
  while ! isRegistered; do
    log Waiting for feature registration to complete...
    sleep 30
  done
  log Feature registration completed. Refreshing the provider...
  # Not sure why this is required, but docs say to do it: https://learn.microsoft.com/en-us/azure/aks/identity-bindings#prerequisites
  az provider register --namespace Microsoft.ContainerService --only-show-errors -o table
else
  info Feature IdentityBindingPreview is already registered, skipping.
fi

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
    -g "$RESOURCE_GROUP" \
    -l "$REGION" \
    -n "$ACR_NAME" \
    --admin-enabled true \
    --sku standard \
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

# Check role assignments.  Role assignments can be created via CLI, but test subscription lacked permission to do so.  Must be done via portal.
IDENTITY_PRINCIPAL=$(az identity show -g ${RESOURCE_GROUP} --name ${IDENTITY} | jq -r '.principalId')
log "[ManualAction]" 1. Ensure ${KEY_VAULT} has a role assignment 'Key Vault Secrets User' for ${IDENTITY_PRINCIPAL}
CURRENT_USER=$(az account show | jq -r '.user.name')
log "[ManualAction]" 2. Ensure ${KEY_VAULT} has a role assignment 'Key Vault Secrets Officer' for ${CURRENT_USER}

if ! az aks list -o table | grep -q ${CLUSTER}; then
  log Creating the cluster
  az aks create \
    -g "$RESOURCE_GROUP" -n "$CLUSTER" \
    --location "$REGION" \
    --node-count 1 \
    --node-vm-size Standard_D4s_v3 \
    --attach-acr $ACR_NAME \
    --only-show-errors \
    --no-ssh-key \
    --enable-oidc-issuer \
    --enable-workload-identity \
    -o table
else
  info Cluster ${CLUSTER} already exists, skipping creation
fi

# Setup environment.
./local-env.sh

# Verify cluster
info Verifying cluster
k get nodes -o wide
k -n kube-system get pods -l azure-workload-identity.io/system=true

info Done