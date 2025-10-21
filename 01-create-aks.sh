#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

az group create -n "$RG" -l "$LOC"

az acr create --admin-enabled true --sku standard -g "$RG" -l "$LOC" -n "$ACR_NAME"

az aks create \
  -g "$RG" -n "$CLUSTER" \
  --location "$LOC" \
  --enable-managed-identity \
  --node-count 1 \
  --node-vm-size Standard_D4s_v3 \
  --attach-acr $ACR_NAME

# Verify
az aks show -g "$RG" -n "$CLUSTER" --query "provisioningState" -o tsv | grep -x Succeeded

# Verify cluster reachable
k get nodes -o wide

# Setup environment.
./local-env.sh
